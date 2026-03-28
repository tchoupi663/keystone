# ECS Fargate Capacity Provider Best Practices

## Overview

AWS ECS supports two Fargate capacity providers:
- **FARGATE**: Standard, reliable compute capacity with guaranteed availability
- **FARGATE_SPOT**: Cost-optimized capacity that can be interrupted with 2-minute warning

Understanding how to configure capacity provider strategies is crucial for balancing cost and reliability.

## Capacity Provider Strategy Parameters

### `base`
- Number of tasks that **must** run on this capacity provider
- Only ONE provider in your strategy can have a non-zero `base`
- The provider with `base > 0` handles the minimum guaranteed capacity

### `weight`
- Determines the relative proportion of tasks beyond `base` to run on this provider
- If multiple providers are specified, tasks are distributed based on weight ratios
- Higher weight = more tasks scheduled on this provider

## Configuration by Environment

### Development Environment

**Goal**: Minimize cost, acceptable interruption risk

```hcl
capacity_provider_strategy = [
  {
    base              = 1
    capacity_provider = "FARGATE_SPOT"
    weight            = 2  # Prefer SPOT when scaling
  },
  {
    base              = 0
    capacity_provider = "FARGATE"
    weight            = 1  # Fallback if SPOT unavailable
  }
]
```

**Characteristics**:
- ✅ ~70% cost savings on compute
- ⚠️ Tasks may be interrupted (2-minute warning)
- ⚠️ Not suitable for production workloads
- ✅ Good for dev/test environments with fault-tolerant apps

### Staging Environment

**Goal**: Balance cost and reliability

```hcl
capacity_provider_strategy = [
  {
    base              = 1
    capacity_provider = "FARGATE"
    weight            = 1  # Equal weight for stable baseline
  },
  {
    base              = 0
    capacity_provider = "FARGATE_SPOT"
    weight            = 2  # Prefer SPOT for scale-out
  }
]
```

**Characteristics**:
- ✅ At least one task always on reliable FARGATE
- ✅ Scale-out uses SPOT for cost savings (2:1 ratio)
- ✅ Production-like reliability testing
- ⚠️ Reduced redundancy during baseline load

### Production Environment

**Goal**: Maximum reliability and availability

```hcl
capacity_provider_strategy = [
  {
    base              = 2  # Minimum two tasks for HA
    capacity_provider = "FARGATE"
    weight            = 1
  },
  {
    base              = 0
    capacity_provider = "FARGATE_SPOT"
    weight            = 1  # SPOT only for burst beyond base
  }
]
```

**Characteristics**:
- ✅ Two tasks always on reliable FARGATE (cross-AZ redundancy)
- ✅ Zero-downtime deployments
- ✅ High availability guarantee
- ✅ SPOT used only for scale-out (not critical path)
- ⚠️ Higher baseline cost (acceptable for production SLAs)

## How Task Distribution Works

### Example: 5 tasks with production config

```hcl
base = 2 (FARGATE), weight = 1 (FARGATE), weight = 1 (FARGATE_SPOT)
```

1. First 2 tasks → **FARGATE** (base requirement)
2. Remaining 3 tasks → Split by weight (1:1 ratio)
   - ~1-2 tasks → **FARGATE**
   - ~1-2 tasks → **FARGATE_SPOT**

### Example: 10 tasks with staging config

```hcl
base = 1 (FARGATE), weight = 1 (FARGATE), weight = 2 (FARGATE_SPOT)
```

1. First task → **FARGATE** (base requirement)
2. Remaining 9 tasks → Split by weight (1:2 ratio)
   - ~3 tasks → **FARGATE**
   - ~6 tasks → **FARGATE_SPOT**

## Cost Considerations

| Capacity Provider | Cost (relative) | Interruption Risk |
|-------------------|-----------------|-------------------|
| FARGATE           | 1.0x (baseline) | None              |
| FARGATE_SPOT      | 0.3x (~70% off) | Yes (2min notice) |

**Example Cost Calculation** (eu-north-1, 0.25 vCPU, 0.5 GB):
- FARGATE: ~$0.0128/hour = $9.22/month per task
- FARGATE_SPOT: ~$0.0038/hour = $2.74/month per task

**Production config (base=2 FARGATE, 3 scaled SPOT)**:
- (2 × $9.22) + (3 × $2.74) = $26.66/month

**Dev config (base=1 SPOT, 0 scaled)**:
- 1 × $2.74 = $2.74/month

## Interruption Handling

FARGATE_SPOT tasks:
1. Receive `SIGTERM` signal
2. Have **2 minutes** to gracefully shut down
3. Are automatically replaced by ECS scheduler

**Best Practices**:
- Configure health checks with sufficient grace period
- Implement graceful shutdown handlers in application code
- Use SPOT only for stateless, fault-tolerant workloads
- Never use SPOT-only for single-task production services

## Common Pitfalls

### ❌ Anti-Pattern: SPOT as Base in Production

```hcl
# WRONG - Production tasks on interruptible compute
capacity_provider_strategy = [
  {
    base              = 2
    capacity_provider = "FARGATE_SPOT"  # ❌
  }
]
```

**Problem**: All tasks can be interrupted simultaneously, causing downtime.

### ❌ Anti-Pattern: No Weight Specified

```hcl
# INCOMPLETE - Weight defaults to 1
capacity_provider_strategy = [
  {
    base              = 1
    capacity_provider = "FARGATE"
  },
  {
    capacity_provider = "FARGATE_SPOT"
  }
]
```

**Problem**: 50/50 distribution may not match intended behavior.

### ✅ Correct Pattern: Explicit Configuration

```hcl
capacity_provider_strategy = [
  {
    base              = 1
    capacity_provider = "FARGATE"
    weight            = 1  # Explicit
  },
  {
    base              = 0
    capacity_provider = "FARGATE_SPOT"
    weight            = 2  # Intentional 2:1 preference
  }
]
```

## Monitoring and Alerts

Track these metrics in CloudWatch:
- `CPUUtilization` and `MemoryUtilization` per capacity provider
- `RunningTaskCount` by capacity provider type
- SPOT interruption frequency

**Recommended Alarms**:
1. Alert when all tasks are on SPOT (production)
2. Alert on frequent SPOT interruptions (> X per day)
3. Alert when FARGATE base capacity is not met

## References

- [AWS Fargate Spot Pricing](https://aws.amazon.com/fargate/pricing/)
- [ECS Capacity Provider Strategies](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/cluster-capacity-providers.html)
- [Handling Spot Interruptions](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/spot-interruptions.html)

## Implementation Locations

- Module definition: [terraform/modules/ecs-service/variables.tf](../terraform/modules/ecs-service/variables.tf)
- Dev config: [terraform/eu-north-1/apps/tfvars/dev.tfvars](../terraform/eu-north-1/apps/tfvars/dev.tfvars)
- Staging config: [terraform/eu-north-1/apps/tfvars/staging.tfvars](../terraform/eu-north-1/apps/tfvars/staging.tfvars)
- Prod config: [terraform/eu-north-1/apps/tfvars/prod.tfvars](../terraform/eu-north-1/apps/tfvars/prod.tfvars)
