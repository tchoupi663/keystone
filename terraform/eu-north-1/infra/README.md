# Infra Layer — Core Networking & Compute

This layer manages the **base infrastructure** for the Keystone environment, including the **VPC**, **ECS Cluster**, and **Observability Pipelines**.

## Purpose

The Infra Layer provides the foundational networking and computing resources required for containerized workloads. It is designed to be **available**, **secure**, and **cost-optimized**.

## Key Features

*   **Multi-AZ VPC:** 3-tier architecture with public, private, and isolated database subnets.
*   **Cost-Efficient NAT (`EC2`):** Uses ARM64 EC2 instances for NAT instead of managed AWS NAT Gateways, reducing fixed costs by ~90% while maintaining auto-recovery via ASG and stable ENIs.
*   **VPC Flow Logs:** Traffic logs are captured and routed via **Amazon Kinesis Data Firehose** into **Grafana Cloud (Loki)** for network monitoring.
*   **ECS Fargate Cluster:** Serverless container orchestration with **CloudWatch Container Insights** for enhanced performance visibility.
*   **Security Groups:** Preconfigured templates for least-privilege access between application, edge, and persistence layers.

## Modules Used

This layer invokes the following internal modules from `terraform/modules/`:
*   **[vpc](../../modules/vpc/README.md)** — Core VPC, subnets, and cost-optimized NAT.
*   **[vpc-flow-logs](../../modules/vpc-flow-logs/README.md)** — Log ingestion pipeline (Firehose to Loki).
*   **[ecs-cluster](../../modules/ecs-cluster/README.md)** — ECS Cluster and Fargate configuration.
*   **[security](../../modules/security/README.md)** — Common IAM roles and baseline security groups.

## Dependencies

This layer is the **second** to be deployed. It depends on:
- **Network Layer:** To ensure Cloudflare tunnels can be integrated later (though the link is loose).
- **Secrets:** Grafana Loki credentials from **AWS SSM Parameter Store** and **Secrets Manager**.

