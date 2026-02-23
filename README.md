# Keystone

![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)
![Kubernetes](https://img.shields.io/badge/kubernetes-%23326ce5.svg?style=flat&logo=kubernetes&logoColor=white)
![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=flat&logo=terraform&logoColor=white)
![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?style=flat&logo=Prometheus&logoColor=white)
![Grafana](https://img.shields.io/badge/grafana-%23F46800.svg?style=flat&logo=grafana&logoColor=white)
![Argocd](https://img.shields.io/badge/argo-%23EF7B4D.svg?style=flat&logo=argo&logoColor=white)

Keystone is a modular, cloud-ready platform engineering project featuring a complete observability stack (Prometheus, Grafana, Loki), automated infrastructure management via Terraform, and flexible compute support (EKS/ECS) designed to streamline application deployments.

## Project Status (WIP)

| Component | Status | Description |
| :--- | :--- | :--- |
| **Observability** | ⚪️ In Progress | Prometheus, Grafana, Loki stacks setup via Terraform |
| **Network (AWS)** | ⚪️ In Progress | VPC, Subnets, Gateways setup |
| **Compute (AWS)** | ⚪️ Planned | EKS / ECS module configurations |
| **Data (AWS/OS)** | ⚪️ Planned | Open-source and AWS RDS Terraform modules |
| **Sample App** | ⚪️ Planned | API and Docker setup for deployment examples |
| **GitOps** | ⚪️ Planned | ArgoCD implementations |

## Features

*   **Infrastructure as Code**: Managed via Terraform.
*   **Observability Stack**: Complete monitoring with Prometheus, Grafana, Loki, and Tempo.
*   **GitOps**: Continuous deployment utilizing ArgoCD. (WIP)
*   **Kubernetes Native**: Built for scalability and reliability with HPA/VPA support. (WIP)

## Project Structure

*   `app/`: Application source code and container definitions.
*   `data/`: Configuration for open-source datastores and managed services like AWS RDS.
*   `infra/`: Layered AWS infrastructure defined in Terraform (Network, DNS, Observability, and Compute split into `eks/` and `ecs/` modules).
*   `kubernetes/`: Base manifests and environment overlays for EKS deployments.
*   `scripts/`: Automation and utility scripts.

## Getting Started

WIP
