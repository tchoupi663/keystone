# Observability Layer — Grafana Dashboards & Folders

This layer manages the **monitoring experience** for the Keystone platform by provisioning unified dashboards and folders in **Grafana Cloud**.

## Purpose

The Observability Layer provides a single source of truth for the entire infrastructure, enabling engineers to visualize performance, health, and logs from a unified interface.

## Key Features

*   **Grafana Folders:** Organizes dashboards into a dedicated hierarchy (e.g., `Keystone - Dev`, `Keystone - Prod`).
*   **Infrastructure Dashboards:** Visualizations for VPC Flow Logs (from Loki) and ECS Cluster health (from Prometheus).
*   **Application Dashboards:** Visualizations for Flask application traces (from Tempo) and custom service-level metrics.
*   **Automated Provisioning:** Dashboard JSON definitions are stored as code (GitOps) and automatically synced with Grafana Cloud.

## Modules Used

This layer uses native Terraform providers for Grafana and does not invoke any internal modules from `terraform/modules/`. It manages:
*   Resources: `grafana_folder`, `grafana_dashboard`.

## Dependencies

The Observability Layer is the **final** layer in the deployment sequence.
- **App Layer:** Provides the data sources (Loki, Prometheus, Tempo) that populate the dashboards.
- **Secrets:** Grafana URL and API tokens from **AWS SSM Parameter Store** and **Secrets Manager**.

