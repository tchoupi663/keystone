data "terraform_remote_state" "infra" {
  backend = "s3"
  config = {
    bucket = var.terraform_state_bucket
    key    = "infra/eu-north-1/infra.tfstate"
    region = "eu-north-1"
  }
}

# data "terraform_remote_state" "data" {
#   backend = "s3"
#   config = {
#     bucket = var.terraform_state_bucket
#     key    = "data/eu-north-1/rds/data.tfstate"
#     region = "eu-north-1"
#   }
# }

data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = var.terraform_state_bucket
    key    = "network/eu-north-1/network.tfstate"
    region = "eu-north-1"
  }
}

data "aws_secretsmanager_secret" "github-token" {
  name = "${var.project}/${var.environment}/github-token"
}

module "apps" {
  source = "../../modules/ecs-service"

  environment = var.environment
  project     = var.project
  region      = var.region

  # Networking — ECS tasks in private subnets with NAT egress
  vpc_id     = data.terraform_remote_state.infra.outputs.vpc_id
  subnet_ids = data.terraform_remote_state.infra.outputs.private_subnets

  assign_public_ip = false

  # Cluster
  ecs_cluster_id          = data.terraform_remote_state.infra.outputs.ecs_cluster_id
  ecs_cluster_name        = data.terraform_remote_state.infra.outputs.ecs_cluster_name
  app_image               = "${var.app_image_repository}:${var.image_tag}"
  github_token_secret_arn = data.aws_secretsmanager_secret.github-token.arn

  # Cloudflare Tunnel
  cloudflare_tunnel_token_secret_arn = data.terraform_remote_state.network.outputs.tunnel_token_secret_arn

  # Security
  ecs_security_group_id = data.terraform_remote_state.infra.outputs.ecs_security_group_id

  # RDS (temporarily unlinked)
  # rds_security_group_id     = data.terraform_remote_state.data.outputs.rds_security_group_id
  # db_host                   = data.terraform_remote_state.data.outputs.rds_address
  # db_name                   = data.terraform_remote_state.data.outputs.rds_db_name
  # db_port                   = data.terraform_remote_state.data.outputs.rds_port
  # db_master_user_secret_arn = data.terraform_remote_state.data.outputs.rds_master_user_secret_arn

  # Container
  container_port = var.container_port
  task_cpu       = var.task_cpu
  task_memory    = var.task_memory

  desired_count          = var.desired_count
  enable_execute_command = var.enable_execute_command
  log_retention_days     = var.log_retention_days

  # Health Check
  health_check_interval     = var.health_check_interval
  health_check_timeout      = var.health_check_timeout
  health_check_retries      = var.health_check_retries
  health_check_start_period = var.health_check_start_period

  enable_scheduled_scaling = var.enable_scheduled_scaling
  # Nightly scale down
  scale_down_cron         = var.scale_down_cron
  scale_up_cron           = var.scale_up_cron
  scale_down_min_capacity = var.scale_down_min_capacity
  scale_down_max_capacity = var.scale_down_max_capacity
  scale_up_min_capacity   = var.scale_up_min_capacity
  scale_up_max_capacity   = var.scale_up_max_capacity

  enable_autoscaling = var.enable_autoscaling
  min_capacity       = var.min_capacity
  max_capacity       = var.max_capacity

  capacity_provider_strategy = var.capacity_provider_strategy

  # Grafana Loki
  grafana_loki_host_ssm_arn       = data.aws_ssm_parameter.grafana_loki_host.arn
  grafana_loki_user_ssm_arn       = data.aws_ssm_parameter.grafana_loki_user.arn
  grafana_loki_api_key_secret_arn = data.aws_secretsmanager_secret.grafana_loki_api_key.arn

  # Grafana Prometheus
  grafana_prometheus_url_ssm_arn  = data.aws_ssm_parameter.grafana_prometheus_url.arn
  grafana_prometheus_user_ssm_arn = data.aws_ssm_parameter.grafana_prometheus_user.arn

  # Grafana Tempo
  grafana_tempo_endpoint_ssm_arn = data.aws_ssm_parameter.grafana_tempo_endpoint.arn
  grafana_tempo_user_ssm_arn     = data.aws_ssm_parameter.grafana_tempo_user.arn
}
