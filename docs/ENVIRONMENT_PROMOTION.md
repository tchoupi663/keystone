# Environment Promotion Strategy

## Overview

This document describes the multi-environment deployment strategy for the Keystone infrastructure, covering the promotion path from development through staging to production.

## Environment Structure

### Available Environments

| Environment | Purpose | Characteristics |
|-------------|---------|-----------------|
| **dev** | Development and testing | Cost-optimized, single-AZ, scheduled scaling, FARGATE_SPOT |
| **staging** | Pre-production validation | Balanced cost/reliability, single-AZ, scheduled scaling, mixed FARGATE/SPOT |
| **prod** | Production workloads | High availability, Multi-AZ, 24/7 operation, 100% FARGATE |

### Directory Structure

```
terraform/eu-north-1/
├── apps/
│   └── tfvars/
│       ├── dev.tfvars
│       ├── staging.tfvars
│       └── prod.tfvars
├── data/
│   └── tfvars/
│       ├── dev.tfvars
│       ├── staging.tfvars
│       └── prod.tfvars
├── infra/
│   └── tfvars/
│       ├── dev.tfvars
│       ├── staging.tfvars
│       └── prod.tfvars
└── observability/
    └── tfvars/
        ├── dev.tfvars
        ├── staging.tfvars
        └── prod.tfvars
```

## Environment-Specific Configuration

### Infrastructure Layer (infra/)

| Configuration | Dev | Staging | Prod |
|--------------|-----|---------|------|
| Public Subnets | 2 | 2 | 3 |
| Private Subnets | 2 | 2 | 3 |
| Database Subnets | 2 | 2 | 3 |

### Data Layer (data/)

| Configuration | Dev | Staging | Prod |
|--------------|-----|---------|------|
| RDS Multi-AZ | ❌ Single-AZ | ❌ Single-AZ | ✅ Multi-AZ |
| Deletion Protection | ❌ Disabled | ❌ Disabled | ✅ Enabled |
| Final Snapshot | ❌ Skip | ❌ Skip | ✅ Required |
| Scheduled Scaling | ✅ Nightly stop | ✅ Nightly stop | ❌ 24/7 |
| Instance Class | db.t4g.micro | db.t4g.micro | db.t4g.small+ |

### Apps Layer (apps/)

| Configuration | Dev | Staging | Prod |
|--------------|-----|---------|------|
| Capacity Provider | FARGATE_SPOT (70%) | FARGATE (70%) | FARGATE (100%) |
| Base Tasks | 1 | 1 | 2 |
| Scheduled Scaling | ✅ Nightly stop | ✅ Nightly stop | ❌ 24/7 |
| Execute Command | Enabled | Disabled | Disabled |

## Parameterization Strategy

### Secret Paths

All environment-specific secrets follow the pattern:
```
keystone/{environment}/{secret-name}
```

**Examples:**
- `keystone/dev/github-token`
- `keystone/staging/github-token`
- `keystone/prod/github-token`
- `keystone/dev/grafana-loki-api-key`
- `keystone/staging/grafana-loki-api-key`
- `keystone/prod/grafana-loki-api-key`

### No Hardcoded Defaults

All `environment` variables in `variables.tf` files **do not have defaults**. This enforces explicit environment specification via tfvars files.

```hcl
variable "environment" {
  description = "Define the environment (dev, staging, prod)"
  type        = string
  # No default - must be explicitly provided via tfvars
}
```

## Deployment Workflow

### Step 1: Infrastructure Layer

Deploy networking, VPC, subnets, security groups, and ECS cluster:

```bash
cd terraform/eu-north-1/infra

# Development
terraform plan -var-file="tfvars/dev.tfvars"
terraform apply -var-file="tfvars/dev.tfvars"

# Staging
terraform plan -var-file="tfvars/staging.tfvars"
terraform apply -var-file="tfvars/staging.tfvars"

# Production
terraform plan -var-file="tfvars/prod.tfvars"
terraform apply -var-file="tfvars/prod.tfvars"
```

### Step 2: Data Layer

Deploy RDS database:

```bash
cd terraform/eu-north-1/data

# Development
terraform plan -var-file="tfvars/dev.tfvars"
terraform apply -var-file="tfvars/dev.tfvars"

# Staging (optional: restore from snapshot)
terraform plan -var-file="tfvars/staging.tfvars"
terraform apply -var-file="tfvars/staging.tfvars"

# Production (required: restore from snapshot)
terraform plan -var-file="tfvars/prod.tfvars"
terraform apply -var-file="tfvars/prod.tfvars"
```

### Step 3: Application Layer

Deploy ECS services:

```bash
cd terraform/eu-north-1/apps

# Development
terraform plan -var-file="tfvars/dev.tfvars"
terraform apply -var-file="tfvars/dev.tfvars"

# Staging
terraform plan -var-file="tfvars/staging.tfvars"
terraform apply -var-file="tfvars/staging.tfvars"

# Production
terraform plan -var-file="tfvars/prod.tfvars"
terraform apply -var-file="tfvars/prod.tfvars"
```

### Step 4: Observability Layer

Deploy Grafana dashboards:

```bash
cd terraform/eu-north-1/observability

# Development
terraform plan -var-file="tfvars/dev.tfvars"
terraform apply -var-file="tfvars/dev.tfvars"

# Staging
terraform plan -var-file="tfvars/staging.tfvars"
terraform apply -var-file="tfvars/staging.tfvars"

# Production
terraform plan -var-file="tfvars/prod.tfvars"
terraform apply -var-file="tfvars/prod.tfvars"
```

## Promotion Checklist

### Before Promoting to Staging

- [ ] All tests pass in dev environment
- [ ] Create AWS Secrets:
  - [ ] `keystone/staging/github-token`
  - [ ] `keystone/staging/grafana-loki-api-key`
- [ ] Update `staging.tfvars` with correct image tag
- [ ] Review capacity provider strategy
- [ ] Verify network outputs from infra layer

### Before Promoting to Production

- [ ] All tests pass in staging environment
- [ ] Conduct security review
- [ ] Create AWS Secrets:
  - [ ] `keystone/prod/github-token`
  - [ ] `keystone/prod/grafana-loki-api-key`
- [ ] Create RDS snapshot from staging (if applicable)
- [ ] Update `prod.tfvars`:
  - [ ] Set production-approved image tag
  - [ ] Configure snapshot_identifier
  - [ ] Review Grafana Cloud workspace IDs
  - [ ] Verify capacity provider strategy (100% FARGATE)
- [ ] Enable CloudWatch alarms
- [ ] Configure SNS notifications for alerts
- [ ] Set up on-call rotation
- [ ] Document rollback procedure
- [ ] Schedule deployment during maintenance window
- [ ] Prepare rollback plan

## State Management

Terraform state is stored in S3:

```
s3://keystone-infra-terraform-state/
├── infra/eu-north-1/infra.tfstate
├── data/eu-north-1/data.tfstate
├── network/eu-north-1/network.tfstate
└── apps/eu-north-1/apps.tfstate
```

**State isolation is achieved through:**
- Different tfvars files for each environment
- Same state bucket, different resource names based on environment variable
- Resources tagged with `Environment` tag

**⚠️ Important:** All environments currently share the same state file path. Consider implementing workspace-based or path-based isolation:

### Option 1: Terraform Workspaces
```bash
terraform workspace new staging
terraform workspace new prod
terraform apply -var-file="tfvars/staging.tfvars"
```

### Option 2: Environment-Specific State Paths
Update `state.tf` in each layer:
```hcl
terraform {
  backend "s3" {
    bucket = "keystone-infra-terraform-state"
    key    = "apps/eu-north-1/${var.environment}/apps.tfstate"  # Dynamic path
    region = "eu-north-1"
  }
}
```

## Image Promotion

Container images follow semantic versioning and should be promoted through environments:

```
dev:     app-1.0.25-dev
         ↓ (after testing)
staging: app-1.0.25
         ↓ (after validation)
prod:    app-1.0.25
```

**Update image tags in tfvars files:**
- `apps/tfvars/dev.tfvars` → `image_tag = "app-1.0.26-dev"`
- `apps/tfvars/staging.tfvars` → `image_tag = "app-1.0.26"`
- `apps/tfvars/prod.tfvars` → `image_tag = "app-1.0.26"` (after staging validation)

## Rollback Procedures

### Application Rollback
1. Update tfvars with previous image tag
2. Run `terraform apply -var-file="tfvars/prod.tfvars"`
3. Monitor CloudWatch Logs and Grafana dashboards

### Database Rollback
1. **If within backup retention period:**
   - Use AWS RDS point-in-time restore
2. **If snapshot available:**
   - Update `snapshot_identifier` in tfvars
   - Run `terraform apply` to create new instance from snapshot
   - Update application connection strings

### Infrastructure Rollback
1. Use Terraform state to revert to previous configuration
2. Run `terraform plan` to verify changes
3. Run `terraform apply` to revert

## Environment-Specific Considerations

### Development
- **Cost Optimization:** FARGATE_SPOT, scheduled scaling, single-AZ
- **Flexibility:** Execute Command enabled for debugging
- **Rapid Iteration:** Quick deployments, no change approval

### Staging
- **Production-Like:** Similar configuration but cost-optimized
- **Testing Ground:** Validate changes before production
- **Data Privacy:** Can use anonymized production data

### Production
- **High Availability:** Multi-AZ RDS, multiple ECS tasks
- **Reliability:** 100% FARGATE, no scheduled scaling
- **Protection:** Deletion protection, final snapshots, change审批

## Monitoring and Alerting

All environments ship logs to Grafana Cloud:
- **Loki:** Application and infrastructure logs
- **Prometheus:** Metrics and time-series data
- **Tempo:** Distributed tracing

**Recommended Alerting Strategy:**
- Dev: Slack notifications
- Staging: Slack + email
- Prod: Slack + email + PagerDuty/OpsGenie

## Next Steps

1. **Implement State Isolation:** Choose workspace or path-based isolation
2. **Automated Testing:** Set up CI/CD to test in dev before promoting
3. **Database Migration Strategy:** Document schema change process across environments
4. **Disaster Recovery:** Document and test full production recovery
5. **Cost Monitoring:** Set up AWS Cost Explorer alerts per environment
6. **Multi-Region:** Plan for `us-east-1` or other regions if needed

## Related Documentation

- [Capacity Provider Strategy](./CAPACITY_PROVIDER_STRATEGY.md)
- [Tagging Implementation](./TAGGING_IMPLEMENTATION.md)
- [Cloudflare ADR](./adr/cloudflare/cloudflare-adr.md)
