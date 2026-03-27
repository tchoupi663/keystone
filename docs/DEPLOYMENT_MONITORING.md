# ECS Deployment Monitoring

## Overview

The ECS service module includes CloudWatch alarms to monitor deployment failures and circuit breaker rollbacks. These alarms notify operators via SNS when deployments fail, ensuring that issues don't go unnoticed.

## Configuration

### Enable Alarms

Set these variables in your apps layer configuration:

```hcl
enable_deployment_alarms = true
alarm_email_endpoints    = ["ops-team@example.com", "devops@example.com"]
```

### SNS Topic

The module creates an SNS topic named `${project}-${environment}-deployment-alarms` that receives alarm notifications. Email subscriptions are automatically created for each address in `alarm_email_endpoints`.

**Important**: Email subscribers must confirm their subscriptions via the confirmation link sent by AWS SNS.

## CloudWatch Alarms

### 1. Deployment Failed Alarm

**Alarm Name**: `${project}-${environment}-ecs-deployment-failed`

**Triggers When**: ECS deployment fails (FailedDeployments metric > 0)

**What It Means**: A deployment was attempted but failed to start tasks successfully.

### 2. Circuit Breaker Triggered Alarm

**Alarm Name**: `${project}-${environment}-ecs-circuit-breaker`

**Triggers When**: ECS deployment circuit breaker rolls back a deployment (DeploymentRollbacks metric > 0)

**What It Means**: The deployment circuit breaker detected that tasks were failing health checks and automatically rolled back to the previous working version.

## Custom Metrics Setup

⚠️ **Important**: AWS ECS does not natively publish `FailedDeployments` or `DeploymentRollbacks` metrics. To make these alarms functional, you must publish custom metrics using one of these approaches:

### Option 1: EventBridge + Lambda (Recommended)

Create EventBridge rules to capture ECS deployment events and publish custom metrics:

1. **Create EventBridge Rule for Deployment Failures**:
   ```json
   {
     "source": ["aws.ecs"],
     "detail-type": ["ECS Deployment State Change"],
     "detail": {
       "eventName": ["SERVICE_DEPLOYMENT_FAILED"]
     }
   }
   ```

2. **Create Lambda Function** to publish CloudWatch metrics:
   ```python
   import boto3
   
   cloudwatch = boto3.client('cloudwatch')
   
   def lambda_handler(event, context):
       service_name = event['detail']['serviceName']
       cluster_name = event['detail']['clusterName']
       
       cloudwatch.put_metric_data(
           Namespace='ECS/Custom',
           MetricData=[
               {
                   'MetricName': 'FailedDeployments',
                   'Value': 1,
                   'Unit': 'Count',
                   'Dimensions': [
                       {'Name': 'ServiceName', 'Value': service_name},
                       {'Name': 'ClusterName', 'Value': cluster_name}
                   ]
               }
           ]
       )
   ```

3. **Configure Lambda as EventBridge Target**.

### Option 2: CloudWatch Logs Metric Filter

Parse ECS task logs for deployment failure patterns:

```bash
aws logs put-metric-filter \
  --log-group-name /aws/ecs/keystone-dev \
  --filter-name ecs-deployment-failed \
  --filter-pattern '[time, request_id, event_type = "ECS DEPLOYMENT FAILED", ...]' \
  --metric-transformations \
      metricName=FailedDeployments,\
      metricNamespace=ECS/Custom,\
      metricValue=1,\
      defaultValue=0
```

### Option 3: Synthetic Monitoring

Use a scheduled Lambda or external monitor to periodically check ECS service deployment status and publish metrics based on the current deployment state.

## Testing Alarms

To test that alarms are working:

1. **Manually set alarm state** (for initial testing):
   ```bash
   aws cloudwatch set-alarm-state \
     --alarm-name keystone-dev-ecs-deployment-failed \
     --state-value ALARM \
     --state-reason "Testing alarm notifications"
   ```

2. **Trigger a real failure** (in dev environment):
   - Deploy an image with a broken health check
   - Deploy with insufficient resources
   - Deploy with invalid environment variables

3. **Verify**:
   - Check email for SNS notifications
   - Review CloudWatch Alarms console
   - Confirm alarm transitions to OK state after resolution

## Notification Format

SNS notifications include:

- **Alarm Name**: Identifies which alarm triggered
- **Description**: Context about what failed
- **State Change**: ALARM → OK transitions
- **Timestamp**: When the alarm state changed
- **Dimensions**: Service and cluster names

## Disabling Alarms

To disable deployment alarms (e.g., in dev environments where noise is high):

```hcl
enable_deployment_alarms = false
```

This removes all alarm resources and the SNS topic from the Terraform plan.

## Best Practices

1. **Environment-Specific Configuration**:
   - **Dev**: Set `enable_deployment_alarms = false` or use minimal endpoints
   - **Staging**: Enable with team email lists
   - **Production**: Enable with PagerDuty/Opsgenie integration

2. **SNS Topic Integration**:
   - Add SMS subscriptions for critical production alerts
   - Configure Lambda functions for Slack/Teams notifications
   - Integrate with incident management systems (PagerDuty, Opsgenie)

3. **Alarm Tuning**:
   - Adjust `evaluation_periods` to reduce noise
   - Set `datapoints_to_alarm` for sustained failures only
   - Use composite alarms for complex conditions

4. **Runbook**:
   - Document response procedures for each alarm
   - Include rollback steps
   - Link to deployment logs and dashboards

## Related Documentation

- [AWS ECS Deployment Circuit Breaker](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-circuit-breaker.html)
- [CloudWatch Custom Metrics](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/publishingMetrics.html)
- [EventBridge Event Patterns for ECS](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_cwe_events.html)
