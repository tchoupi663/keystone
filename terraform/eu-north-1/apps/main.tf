data "terraform_remote_state" "infra" {
  backend = "s3"
  config = {
    bucket = "keystone-infra-terraform-state"
    key    = "infra/eu-north-1/infra.tfstate"
    region = "eu-north-1"
  }
  #workspace = terraform.workspace
}

data "terraform_remote_state" "data" {
  backend = "s3"
  config = {
    bucket = "keystone-infra-terraform-state"
    key    = "data/eu-north-1/data.tfstate"
    region = "eu-north-1"
  }
  #workspace = terraform.workspace
}
data "aws_secretsmanager_secret" "github-token" {
  name = var.github_token_secret_name
}

data "aws_secretsmanager_secret" "grafana_loki_api_key" {
  name = "keystone/${var.environment}/grafana-loki-api-key"
}

module "apps" {
  source = "../../modules/ecs-service"

  environment = var.environment
  project     = var.project
  region      = var.region

  # Networking
  vpc_id     = data.terraform_remote_state.infra.outputs.vpc_id
  subnet_ids = data.terraform_remote_state.infra.outputs.private_subnets

  assign_public_ip = false

  # Cluster
  ecs_cluster_id          = data.terraform_remote_state.infra.outputs.ecs_cluster_id
  ecs_cluster_name        = data.terraform_remote_state.infra.outputs.ecs_cluster_name
  app_image               = "${var.app_image_repository}:${var.image_tag}"
  github_token_secret_arn = data.aws_secretsmanager_secret.github-token.arn

  # ALB
  alb_security_group_id = data.terraform_remote_state.infra.outputs.alb_security_group_id
  alb_target_group_arn  = data.terraform_remote_state.infra.outputs.alb_target_group_arn

  # Security
  ecs_security_group_id = data.terraform_remote_state.infra.outputs.ecs_security_group_id

  # RDS
  rds_security_group_id     = data.terraform_remote_state.data.outputs.rds_security_group_id
  db_host                   = data.terraform_remote_state.data.outputs.rds_address
  db_name                   = data.terraform_remote_state.data.outputs.rds_db_name
  db_port                   = data.terraform_remote_state.data.outputs.rds_port
  db_master_user_secret_arn = data.terraform_remote_state.data.outputs.rds_master_user_secret_arn

  # Container
  container_port = 80
  task_cpu       = "512"
  task_memory    = "1024"

  desired_count          = 1
  enable_execute_command = false
  log_retention_days     = 14
  enable_autoscaling     = true
  enable_scheduled_scaling = true

  # Nightly scale down
  scale_down_cron         = "0 20 * * ? *"
  scale_up_cron           = "0 7 * * ? *"
  scale_down_min_capacity = 0
  scale_down_max_capacity = 0
  scale_up_min_capacity   = 1
  scale_up_max_capacity   = 1

  capacity_provider_strategy = var.capacity_provider_strategy

  # Grafana Loki
  grafana_loki_host               = "logs-prod-035.grafana.net"
  grafana_loki_user               = var.grafana_loki_user
  grafana_loki_api_key_secret_arn = data.aws_secretsmanager_secret.grafana_loki_api_key.arn

  # Grafana Prometheus
  grafana_prometheus_url          = var.grafana_prometheus_url
  grafana_prometheus_user         = var.grafana_prometheus_user
}
