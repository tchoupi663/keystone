# Keystone Terraform Modules

This directory contains reusable, modular Terraform components used to provision the Keystone infrastructure on AWS and Cloudflare. 

Each module is designed to be self-contained and follows the project's tagging and naming conventions. For detailed technical specifications (inputs, outputs, resources), refer to the `README.md` within each module's directory.

## Module Overview

### Network Layer
*   **[vpc](vpc/README.md)** — Provisions a multi-AZ VPC with public, private, and database subnets. Includes NAT Gateway (or cost-effective `fck-nat` instance) and VPC Endpoints for S3/ECR.
*   **[vpc-flow-logs](vpc-flow-logs/README.md)** — Configures VPC Flow Logs to be sent to Amazon Kinesis Data Firehose for ingestion into Grafana Cloud (Loki).
*   **[alb](alb/README.md)** — Deploys an Application Load Balancer (ALB) with listener rules and target groups for ECS services.
*   **[acm](acm/README.md)** — Manages AWS Certificate Manager (ACM) certificates for secure TLS termination.

### Security & Edge (Cloudflare)
*   **[cloudflare](cloudflare/README.md)** — Basic Cloudflare account and zone configuration.
*   **[cloudflare-dns](cloudflare-dns/README.md)** — Manages DNS records and zone settings within Cloudflare.
*   **[cloudflare-security](cloudflare-security/README.md)** — Configures WAF rules, page rules, and other security settings at the edge.
*   **[cloudflare-tunnel](cloudflare-tunnel/README.md)** — Sets up Cloudflare Zero Trust Tunnels (`cloudflared`) for secure ingress without public-facing ALB endpoints.
*   **[dns](dns/README.md)** — General DNS configuration for external services.
*   **[security](security/README.md)** — Common IAM roles, policies, and security group templates used across modules.

### Application Layer
*   **[ecs-cluster](ecs-cluster/README.md)** — Provisions an Amazon ECS Cluster on Fargate with CloudWatch Container Insights enabled.
*   **[ecs-service](ecs-service/README.md)** — Deploys containerized applications on ECS Fargate, including sidecars for `cloudflared` (tunnel) and `alloy` (observability).

### Data & Performance
*   **[rds](rds/README.md)** — Provisions a managed PostgreSQL database instance with automated backups and Multi-AZ support.
*   **[cloudfront](cloudfront/README.md)** — Configures Amazon CloudFront distributions for global content delivery and static asset caching.

## Maintenance

Individual module documentation is automatically generated using `terraform-docs`. To refresh the documentation after making changes to variables or outputs, run:

```bash
terraform-docs markdown table --config ../.terraform-docs.yml . > README.md
```
