# ADR: Transition to Cloudflare for Hosting Infrastructure
 
**Date:** March 26, 2026

## Context

Operating a Flask application on AWS with traditional infrastructure (ALB + NAT Gateway) costs approximately $60/month for networking alone, consuming 30% of a $200 multi-month hosting budget before accounting for compute, storage, or database costs.

## Decision

Migrate to Cloudflare-based architecture using:
- Cloudflare Tunnel for secure ingress (eliminating ALB)
- Cloudflare DNS (free tier)
- Cloudflare WAF (free tier)
- Public subnets for ECS tasks (no NAT Gateway required)
- Fewer Route 53 hosted zones

## Consequences

**Positive:**
- **Cost savings:** ~$60/month reduction by eliminating ALB ($16/month) and NAT Gateway ($32-45/month)
- **Security:** Cloudflare WAF and DDoS protection on free tier, superior to unmanaged ALB
- **Simplicity:** Cloudflare Tunnel eliminates manual security group management and ingress configuration
- **Budget reallocation:** Freed funds can be invested in Multi-AZ RDS or additional ECS tasks

**Negative:**
- Dependency on Cloudflare Tunnel daemon uptime

**Technical Notes:**
- Public subnet deployment is secure when combined with Cloudflare Tunnel (no exposed ports)
- For simple Flask applications, the theoretical risks mitigated by private subnets + NAT are minimal
- This architecture remains pragmatic and defensible for non-enterprise compliance requirements