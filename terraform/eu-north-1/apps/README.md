# App Layer — Containerized Services & Scaling

This layer manages the **application deployment** and **service lifecycle** for the Keystone platform on **Amazon ECS Fargate**.

## Purpose

The App Layer is responsible for deploying the containerized Python (Flask) application and providing unified observability through **Grafana Cloud**. It ensures high availability and cost-optimization through performance-driven **Auto Scaling**.

## Key Features

*   **Serverless ECS Fargate:** No EC2 instance management, automatic patching, and resource isolation.
*   **Target Tracking Auto Scaling:** Dynamic scaling based on CPU and Memory utilization thresholds.
*   **Container Image:** The container image is fetched from **Github Packages**.
*   **Scheduled Nightly Scaling:** Automatic cost-reduction by scaling down services during off-peak hours (e.g., 2 AM to 6 AM).
*   **Sidecars:**
    *   **`cloudflared`**: Connects the service to the Edge, and thus to the users, via Cloudflare Tunnels (Private Link equivalent).
    *   **`grafana-alloy`**: Unified agent for collecting logs (Loki), metrics (Prometheus) and traces (Tempo).
*   **Health Checks:** Configurable container-level health validation for rolling updates.

## Modules Used

This layer invokes the following internal modules from `terraform/modules/`:
*   **[ecs-service](../../modules/ecs-service/README.md)** — Core service deployment, IAM roles, Task Definitions, and Scaling.

## Dependencies

The App Layer is **third** in the deployment sequence and depends on multiple prior layers:
- **Network Layer:** To retrieve Cloudflare Tunnel tokens.
- **Infra Layer:** To retrieve the VPC ID, private subnet IDs, and ECS Cluster identifiers.
- **Docker Registry:** To pull verified application images (handled via CI/CD).
- **Secrets Manager:** To retrieve GitHub tokens and Grafana API keys securely.

