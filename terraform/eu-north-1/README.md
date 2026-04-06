# Keystone Infrastructure — eu-north-1

This directory contains the infrastructure-as-code (IaC) for the **Keystone** project in the `eu-north-1` (Stockholm) region. The infrastructure is managed using **Terraform** and orchestrated with **Terramate** and **Terragrunt** for a modular, dry, and scalable approach.

## Architecture Layers

The infrastructure is broken down into 4 distinct layers (stacks), which must be deployed in a specific sequence to ensure dependencies are met.

| Layer | Order | Description |
| :--- | :---: | :--- |
| **[Network](network/README.md)** | 1 | Edge security (Cloudflare), ingress tunnels, and DNS configuration. |
| **[Infra](infra/README.md)** | 2 | Core AWS networking (VPC), security groups, ECS cluster, and logging pipelines. |
| **[App](apps/README.md)** | 3 | Containerized application deployment, service scaling, and observability sidecars. |
| **[Observability](observability/README.md)** | 4 | Grafana Cloud dashboards, folders, and monitoring configuration. |

## Deployment Workflow

Keystone uses **Terramate** to manage dependencies and trigger deployments.

Start by running `terramate generate` to generate the stack files. Then, run in root the following:
```bash
terramate run --tags $env -- terragrunt init 
terramate run --tags $env -- terragrunt apply 
```

### CI/CD
Deployments are automated via GitHub Actions. Every merge to `main` triggers a plan and apply workflow that validates each layer before execution.

## Global Configuration

- **Providers:** AWS, Cloudflare, Grafana.
- **Backend:** Remote state is stored in an S3 bucket with DynamoDB locking (managed via Terragrunt).
- **Naming:** Follows the pattern `${project}-${environment}-${resource}`.
