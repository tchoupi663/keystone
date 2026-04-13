
environment = "prod"

capacity_provider_strategy = [
  {
    capacity_provider = "FARGATE"
    weight            = 1
    base              = 1
  },
  {
    capacity_provider = "FARGATE_SPOT"
    weight            = 2
    base              = 0
  }
]

app_image_repository = "ghcr.io/tchoupi663/keystone"
image_tag            = "app-1.1.2"

# Service configuration
container_port         = 8080
task_cpu               = "256"
task_memory            = "512"
desired_count          = 1
enable_execute_command = false
log_retention_days     = 30

# Scaling
enable_autoscaling       = true
min_capacity             = 1
max_capacity             = 3
enable_scheduled_scaling = false

# Health Check
health_check_interval     = 30
health_check_timeout      = 5
health_check_retries      = 3
health_check_start_period = 60

scale_down_cron         = "0 21 * * ? *"
scale_up_cron           = "0 5 * * ? *"
scale_down_min_capacity = 0
scale_down_max_capacity = 0
scale_up_min_capacity   = 1
scale_up_max_capacity   = 3
