# Keystone

![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=flat&logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?style=flat&logo=amazon-aws&logoColor=white)
![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=flat&logo=docker&logoColor=white)
![Python](https://img.shields.io/badge/python-3670A0?style=flat&logo=python&logoColor=ffdd54)

Keystone is a modular, layered AWS infrastructure project managed via Terraform. It is designed to demonstrate deploying a containerized Python (Flask) web application on Amazon ECS Fargate. The project implements a secure, robust network architecture, a managed PostgreSQL database, and automated application load balancing.

> **Note:** This project has evolved from a Kubernetes-centric platform into a serverless AWS native (ECS Fargate) deployment architecture.

## Features

*   **Infrastructure as Code**: Managed via structured, layered Terraform modules.
*   **Network Security**: Custom VPC architecture with isolated public, private, and database subnets using AWS native best practices.
*   **Serverless Compute**: Fully managed container orchestration utilizing AWS ECS Fargate and ECR.
*   **Load Balancing**: Application Load Balancer (ALB) configured with HTTPS, ACM certificates, and host-based routing.
*   **Managed Database**: AWS RDS (PostgreSQL) deployed in private database subnets.
*   **Observability**: Integrated with AWS CloudWatch for Container Insights and logging.
*   **Sample Python App**: A Flask web application that connects to the RDS instance to display ongoing AWS costs. 

## Project Structure

The repository is logically separated into application code and infrastructure layers:

*   `app/`: Contains the front-end and back-end source code for the Flask application, along with Docker definitions (`docker-compose.yml`, etc.).
*   `architecture.md`: Detailed visual architecture diagram (Mermaid) and infrastructure layering explanation.
*   `terraform/`: Contains all Terraform configurations, cleanly separated into functional layers to avoid massive state files:
    *   `infra/`: The baseline infrastructure layer consisting of the VPC, ALB, ECS Cluster, ECR, and VPC endpoints.
    *   `data/`: The database layer with RDS PostgreSQL and Secrets Manager integrations.
    *   `app/`: The compute layer managing ECS Fargate services, Task Definitions, and IAM networking roles.
    *   `modules/`: Custom, reusable Terraform modules (`vpc`, `alb`, `ecs-cluster`, etc.).

## Architecture Quick Glance

Deploys over 3 distinct terraform layers that read via `terraform_remote_state`:
1. **Infra Layer**: Provisions VPC, subnets, gateways, ALB, and ECR.
2. **Data Layer**: Provisions RDS and handles secure credentials in AWS Secrets Manager.
3. **App Layer**: Provisions ECS services, pulls the application image from ECR, and connects to the RDS instance.

For the full network flow and architectural diagrams, please see [architecture.md](architecture.md).
