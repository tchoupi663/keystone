# RDS Backup and Restore Runbook

## Overview
This document provides detailed procedures for backing up and restoring the Keystone RDS PostgreSQL database across all environments (dev, staging, production).

---

## Table of Contents
1. [Backup Strategy](#backup-strategy)
2. [Automated Backups](#automated-backups)
3. [Manual Snapshots](#manual-snapshots)
4. [Cross-Region Backup Replication](#cross-region-backup-replication)
5. [Restore Procedures](#restore-procedures)
6. [Disaster Recovery](#disaster-recovery)
7. [Testing and Validation](#testing-and-validation)

---

## Backup Strategy

### Backup Types
- **Automated Daily Backups**: RDS automated backups (7-day retention)
- **Final Snapshots**: Taken when database is destroyed (production only)
- **Manual Snapshots**: On-demand backups before major changes
- **Cross-Region Replicas**: Production backups copied to `eu-west-1` for DR

### Retention Policies
| Environment | Automated Backups | Final Snapshot | Cross-Region Backup |
|-------------|-------------------|----------------|---------------------|
| **dev**     | 7 days            | ❌ Disabled    | ❌ Disabled         |
| **staging** | 7 days            | ✅ Enabled     | ⚠️ Optional         |
| **prod**    | 7 days            | ✅ Enabled     | ✅ Enabled (14 days)|

---

## Automated Backups

### Configuration
Automated backups are configured in the RDS module:
- **Backup Window**: `03:00-04:00 UTC` (daily)
- **Maintenance Window**: `Sunday 04:30-05:30 UTC`
- **Retention**: 7 days
- **Backup Location**: Same region as RDS instance (`eu-north-1`)

### Viewing Automated Backups
```bash
# List automated backups for an environment
aws rds describe-db-instances \\
  --db-instance-identifier keystone-prod-db \\
  --region eu-north-1 \\
  --query 'DBInstances[0].LatestRestorableTime'

# List all automated snapshots (point-in-time recovery)
aws rds describe-db-instances \\
  --db-instance-identifier keystone-prod-db \\
  --region eu-north-1
```

---

## Manual Snapshots

### When to Create Manual Snapshots
1. **Before major schema migrations**
2. **Before application deployments that modify data**
3. **Before environment promotion** (e.g., staging → prod)
4. **For long-term archival** (beyond 7 days)

### Creating a Manual Snapshot

#### Via AWS CLI
```bash
# Create a manual snapshot
aws rds create-db-snapshot \\
  --db-instance-identifier keystone-prod-db \\
  --db-snapshot-identifier keystone-prod-manual-$(date +%Y%m%d-%H%M%S) \\
  --region eu-north-1 \\
  --tags Key=Environment,Value=prod \\
         Key=Purpose,Value=pre-deployment-backup \\
         Key=CreatedBy,Value=$(whoami)

# Monitor snapshot creation
aws rds describe-db-snapshots \\
  --db-snapshot-identifier keystone-prod-manual-20260327-103000 \\
  --region eu-north-1 \\
  --query 'DBSnapshots[0].[Status,PercentProgress]'
```

#### Via AWS Console
1. Navigate to **RDS → Databases**
2. Select database (e.g., `keystone-prod-db`)
3. Click **Actions → Take snapshot**
4. Enter snapshot name with timestamp: `keystone-prod-manual-YYYYMMDD-HHMMSS`
5. Add tags for tracking
6. Click **Take snapshot**

---

## Cross-Region Backup Replication

### Overview
Production backups are automatically replicated to `eu-west-1` for disaster recovery using AWS Backup.

### Configuration
Defined in [`terraform/eu-north-1/data/tfvars/prod.tfvars`](../terraform/eu-north-1/data/tfvars/prod.tfvars):
```hcl
enable_cross_region_backup = true
backup_replication_region  = "eu-west-1"
```

### How It Works
1. **Daily Backup**: AWS Backup creates snapshot at 02:00 UTC
2. **Cross-Region Copy**: Snapshot is copied to `eu-west-1`
3. **Retention**: Primary region: 7 days, DR region: 14 days

### Verifying Cross-Region Backups
```bash
# Check primary region backups
aws backup list-recovery-points-by-backup-vault \\
  --backup-vault-name keystone-prod-rds-backup-vault \\
  --region eu-north-1

# Check DR region backups
aws backup list-recovery-points-by-backup-vault \\
  --backup-vault-name keystone-prod-rds-dr-vault \\
  --region eu-west-1
```

---

## Restore Procedures

### Prerequisites
- AWS CLI configured with appropriate credentials
- Terraform workspace prepared
- Database credentials available (or managed via Secrets Manager)

---

### Restore Option 1: Point-in-Time Recovery (PITR)

**Use Case**: Rollback to any time within the last 7 days

#### Steps
```bash
# 1. Determine target restore time
TARGET_TIME="2026-03-26T15:30:00Z"  # UTC format

# 2. Restore to a new RDS instance
aws rds restore-db-instance-to-point-in-time \\
  --source-db-instance-identifier keystone-prod-db \\
  --target-db-instance-identifier keystone-prod-db-restored \\
  --restore-time "$TARGET_TIME" \\
  --region eu-north-1

# 3. Monitor restoration progress
aws rds describe-db-instances \\
  --db-instance-identifier keystone-prod-db-restored \\
  --region eu-north-1 \\
  --query 'DBInstances[0].DBInstanceStatus'

# 4. Once status is 'available', validate data
# 5. Update application to point to restored instance
# 6. After validation, delete old instance if needed
```

---

### Restore Option 2: From Manual or Automated Snapshot

**Use Case**: Restore from a known-good snapshot

#### Step 1: List Available Snapshots
```bash
# List manual snapshots
aws rds describe-db-snapshots \\
  --db-instance-identifier keystone-prod-db \\
  --snapshot-type manual \\
  --region eu-north-1 \\
  --query 'DBSnapshots[*].[DBSnapshotIdentifier,SnapshotCreateTime]' \\
  --output table

# List automated snapshots
aws rds describe-db-snapshots \\
  --db-instance-identifier keystone-prod-db \\
  --snapshot-type automated \\
  --region eu-north-1
```

#### Step 2: Restore via Terraform (Recommended)

Update [`terraform/eu-north-1/data/tfvars/prod.tfvars`](../terraform/eu-north-1/data/tfvars/prod.tfvars):
```hcl
snapshot_identifier = "keystone-prod-manual-20260326-120000"
```

Apply changes:
```bash
cd terraform/eu-north-1/data
terraform plan -var-file=tfvars/prod.tfvars
terraform apply -var-file=tfvars/prod.tfvars
```

**⚠️ Warning**: This will **replace** the existing database. Use this only for full environment restoration.

#### Step 3: Restore via AWS CLI (Alternative)
```bash
# Restore snapshot to a new instance
aws rds restore-db-instance-from-db-snapshot \\
  --db-instance-identifier keystone-prod-db-restored \\
  --db-snapshot-identifier keystone-prod-manual-20260326-120000 \\
  --db-instance-class db.t4g.micro \\
  --multi-az \\
  --publicly-accessible false \\
  --region eu-north-1

# Tag the restored instance
aws rds add-tags-to-resource \\
  --resource-name "arn:aws:rds:eu-north-1:ACCOUNT_ID:db:keystone-prod-db-restored" \\
  --tags Key=Environment,Value=prod Key=RestoredFrom,Value=keystone-prod-manual-20260326-120000
```

---

### Restore Option 3: From Cross-Region Backup (Disaster Recovery)

**Use Case**: Primary region (`eu-north-1`) unavailable

#### Step 1: Identify Latest DR Backup
```bash
# List backups in DR region
aws backup list-recovery-points-by-backup-vault \\
  --backup-vault-name keystone-prod-rds-dr-vault \\
  --region eu-west-1 \\
  --query 'RecoveryPoints[*].[RecoveryPointArn,CreationDate]' \\
  --output table
```

#### Step 2: Restore in DR Region
```bash
# Restore from AWS Backup recovery point
aws backup start-restore-job \\
  --recovery-point-arn "arn:aws:backup:eu-west-1:ACCOUNT_ID:recovery-point:XXXXX" \\
  --metadata '{
    "DBInstanceIdentifier":"keystone-prod-db-dr",
    "DBInstanceClass":"db.t4g.micro",
    "Engine":"postgres",
    "MultiAZ":"true"
  }' \\
  --iam-role-arn "arn:aws:iam::ACCOUNT_ID:role/AWSBackupDefaultServiceRole" \\
  --region eu-west-1
```

#### Step 3: Update DNS/Application Configuration
1. Update Route 53 or DNS to point to DR region endpoint
2. Update connection strings in application configuration
3. Verify application connectivity

---

## Disaster Recovery

### DR Scenarios

#### Scenario 1: Database Corruption
**Recovery Time**: 15-30 minutes  
**Procedure**: Use Point-in-Time Recovery to restore to pre-corruption state

#### Scenario 2: Accidental Data Deletion
**Recovery Time**: 15-30 minutes  
**Procedure**: Restore from latest automated or manual snapshot

#### Scenario 3: Region Outage
**Recovery Time**: 1-2 hours  
**Procedure**: Activate DR environment in `eu-west-1` using cross-region backups

### DR Testing Schedule
- **Dev/Staging**: Quarterly restore testing
- **Production**: Monthly restore validation + Annual DR failover drill

---

## Testing and Validation

### Monthly Backup Validation (Production)
```bash
#!/bin/bash
# Monthly backup validation script

ENVIRONMENT="prod"
SNAPSHOT_ID="keystone-${ENVIRONMENT}-validation-$(date +%Y%m%d)"
RESTORE_INSTANCE="keystone-${ENVIRONMENT}-test-restore"

echo "Creating validation snapshot..."
aws rds create-db-snapshot \\
  --db-instance-identifier keystone-${ENVIRONMENT}-db \\
  --db-snapshot-identifier $SNAPSHOT_ID \\
  --region eu-north-1

echo "Waiting for snapshot to complete..."
aws rds wait db-snapshot-completed \\
  --db-snapshot-identifier $SNAPSHOT_ID \\
  --region eu-north-1

echo "Restoring snapshot to test instance..."
aws rds restore-db-instance-from-db-snapshot \\
  --db-instance-identifier $RESTORE_INSTANCE \\
  --db-snapshot-identifier $SNAPSHOT_ID \\
  --db-instance-class db.t4g.micro \\
  --no-publicly-accessible \\
  --region eu-north-1

echo "Backup validation complete. Remember to delete test instance after verification."
```

### Validation Checklist
- [ ] Snapshot creation successful
- [ ] Snapshot visible in RDS console
- [ ] Cross-region copy completed (prod only)
- [ ] Test restoration to temporary instance
- [ ] Database connection successful
- [ ] Sample data integrity verified
- [ ] Test instance terminated after validation

---

## Troubleshooting

### Common Issues

#### Issue: Snapshot Creation Fails
**Symptoms**: `aws rds create-db-snapshot` returns error  
**Solutions**:
- Check if database is in `available` state
- Verify IAM permissions (`rds:CreateDBSnapshot`)
- Ensure no other snapshot operations are in progress

#### Issue: Restore Takes Longer Than Expected
**Symptoms**: Restoration status stuck at "creating"  
**Solutions**:
- Large databases take longer (estimate: 1 GB = 1-2 minutes)
- Check CloudWatch logs for RDS events
- Verify network connectivity and security groups

#### Issue: Cross-Region Backup Not Appearing
**Symptoms**: Backup visible in primary region but not DR region  
**Solutions**:
- Check AWS Backup IAM role permissions
- Verify DR backup vault exists in target region
- Review CloudTrail for backup job failures

---

## Reference

### Important Files
- **RDS Module**: [`terraform/modules/rds/main.tf`](../terraform/modules/rds/main.tf)
- **Data Layer Config**: [`terraform/eu-north-1/data/main.tf`](../terraform/eu-north-1/data/main.tf)
- **Production tfvars**: [`terraform/eu-north-1/data/tfvars/prod.tfvars`](../terraform/eu-north-1/data/tfvars/prod.tfvars)

### Related Documentation
- [Environment Promotion](./ENVIRONMENT_PROMOTION.md)
- [Tagging Implementation](./TAGGING_IMPLEMENTATION.md)

### Useful AWS CLI Commands
```bash
# List all RDS instances
aws rds describe-db-instances --region eu-north-1

# Get database endpoint
aws rds describe-db-instances \\
  --db-instance-identifier keystone-prod-db \\
  --query 'DBInstances[0].Endpoint.Address' \\
  --output text

# Check backup retention
aws rds describe-db-instances \\
  --db-instance-identifier keystone-prod-db \\
  --query 'DBInstances[0].BackupRetentionPeriod'

# Delete old manual snapshots (use with caution)
aws rds delete-db-snapshot \\
  --db-snapshot-identifier keystone-dev-manual-20260101-000000
```

---

## Support

For issues or questions regarding backups and restores:
1. Check CloudWatch Logs: `/aws/rds/instance/keystone-{env}-db`
2. Review RDS Events in AWS Console
3. Contact DevOps team
4. Escalate to AWS Support (production incidents)
