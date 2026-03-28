# Keystone

![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=flat&logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?style=flat&logo=amazon-aws&logoColor=white)
![Cloudflare](https://img.shields.io/badge/Cloudflare-%23F38020.svg?style=flat&logo=cloudflare&logoColor=white)
![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=flat&logo=docker&logoColor=white)
![Python](https://img.shields.io/badge/python-3670A0?style=flat&logo=python&logoColor=ffdd54)

### WIP

Keystone is a modular, cost-optimized AWS infrastructure project managed via Terraform. It features a secure, NAT-less networking architecture using **Cloudflare Zero Trust (Tunnels)** to expose a containerized Python (Flask) web application running on Amazon ECS Fargate.

> [!NOTE]
> This project has evolved from an ALB-centric stack into a highly cost-efficient architecture by replacing AWS NAT Gateways and Load Balancers with Cloudflare Tunnels.

## Features

*   **Zero Trust Ingress**: Replaced Application Load Balancer (ALB) with **Cloudflare Tunnels**, providing secure access without exposing any inbound ports.
*   **Cost-Optimized Networking**: Eliminated AWS NAT Gateways by running ECS tasks in public subnets with egress-only security policies.
*   **Observability-First**: Integrated with **Grafana Cloud** (Loki, Prometheus, Tempo) for unified logging, metrics, and tracing.
*   **VPC Flow Logs Pipeline**: Automated log ingestion from VPC Flow Logs to Grafana Loki via Kinesis Data Firehose.
*   **Automated Scaling**: Includes scheduled scaling actions to optimize costs (e.g., nightly scale-down to 0, morning scale-up to 1).
*   **Managed Database**: Persistent AWS RDS (PostgreSQL) deployed in private database subnets.

## Project Structure

The project is structured into five distinct Terraform layers to ensure clean isolation and manageable state:

1.  **Network Layer (`terraform/eu-north-1/network/`)**: Manages Cloudflare resources, including the Zero Trust Tunnel and DNS records.
2.  **Infra Layer (`terraform/eu-north-1/infra/`)**: Provisions the baseline VPC (Public/Private/DB subnets), ECS Cluster, and the Kinesis-to-Loki logging pipeline.
3.  **Data Layer (`terraform/eu-north-1/data/`)**: Provisions the RDS PostgreSQL instance and handles secure credentials in AWS Secrets Manager.
4.  **App Layer (`terraform/eu-north-1/apps/`)**: Deploys the ECS Fargate service with `cloudflared` and `alloy` sidecars for connectivity and telemetry.
5.  **Observability Layer (`terraform/eu-north-1/observability/`)**: Manages Grafana dashboards and folders directly via Terraform.

## Architecture Summary

The flow follows a reverse-proxy pattern via Cloudflare:
1.  **Cloudflare Edge** receives traffic and routes it through the established **Tunnel**.
2.  The `cloudflared` sidecar in the ECS task pulls traffic from the tunnel and routes it to the local app container.
3.  **Grafana Alloy** scrapes metrics from the app and forwards them to Grafana Cloud.
4.  **Kinesis Data Firehose** ingests VPC Flow Logs and streams them directly to Grafana Loki.


