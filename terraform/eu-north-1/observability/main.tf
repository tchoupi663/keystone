
data "aws_secretsmanager_secret" "grafana_workspace_token" {
  name = var.grafana_workspace_token_secret_name
}

data "aws_secretsmanager_secret_version" "grafana_workspace_token" {
  secret_id = data.aws_secretsmanager_secret.grafana_workspace_token.id
}

provider "grafana" {
  url  = var.grafana_url
  auth = jsondecode(data.aws_secretsmanager_secret_version.grafana_workspace_token.secret_string)["grafana-workspace-token"]
}

resource "grafana_folder" "keystone" {
  title = "Keystone ${title(var.environment)}"
}

resource "grafana_dashboard" "app_dashboard" {
  folder      = grafana_folder.keystone.id
  config_json = file("${path.module}/dashboards/app_dashboard.json")
  overwrite   = true
}

resource "grafana_dashboard" "infra_dashboard" {
  folder      = grafana_folder.keystone.id
  config_json = file("${path.module}/dashboards/infra_dashboard.json")
  overwrite   = true
}

resource "grafana_dashboard" "rds_dashboard" {
  folder      = grafana_folder.keystone.id
  config_json = file("${path.module}/dashboards/rds_dashboard.json")
  overwrite   = true
}

resource "grafana_dashboard" "ecs_dashboard" {
  folder      = grafana_folder.keystone.id
  config_json = file("${path.module}/dashboards/ecs_dashboard.json")
  overwrite   = true
}


# ──────────────────────────────────────────────
# Grafana Alert Rules — VPC Flow Log Anomalies
# ──────────────────────────────────────────────

resource "grafana_rule_group" "vpc_flow_log_alerts" {
  name             = "VPC Flow Log Anomalies"
  folder_uid       = grafana_folder.keystone.uid
  interval_seconds = 300

  # Alert: High rate of rejected VPC flows (potential port scan or misconfigured SG)
  rule {
    name      = "High Rejected VPC Flows"
    condition = "threshold"

    # Query rejected flow logs from Loki
    data {
      ref_id         = "loki_query"
      datasource_uid = var.grafana_loki_datasource_uid

      relative_time_range {
        from = 300
        to   = 0
      }

      model = jsonencode({
        expr     = "sum(rate({job=\"vpc-flow-logs\"} |= \"REJECT\" [5m]))"
        refId    = "loki_query"
        queryType = "range"
      })
    }

    # Threshold: alert if rejected flows exceed 10/min over 5m
    data {
      ref_id         = "threshold"
      datasource_uid = "-100"

      relative_time_range {
        from = 0
        to   = 0
      }

      model = jsonencode({
        type       = "threshold"
        conditions = [{
          evaluator = { type = "gt", params = [10] }
          operator  = { type = "and" }
          query     = { params = ["loki_query"] }
          reducer   = { type = "last" }
        }]
        refId = "threshold"
      })
    }

    for                = "5m"
    no_data_state      = "OK"
    exec_err_state     = "Alerting"
    annotations = {
      summary     = "High rate of rejected VPC flows detected in ${var.environment}"
      description = "More than 10 rejected flows/min observed. Possible port scan, misconfigured security group, or unauthorized access attempt."
    }
    labels = {
      severity    = "warning"
      environment = var.environment
    }
  }

  # Alert: Unusual outbound traffic volume (potential data exfiltration)
  rule {
    name      = "Unusual Outbound Traffic"
    condition = "threshold"

    data {
      ref_id         = "loki_query"
      datasource_uid = var.grafana_loki_datasource_uid

      relative_time_range {
        from = 3600
        to   = 0
      }

      model = jsonencode({
        expr      = "sum(rate({job=\"vpc-flow-logs\"} | json | action=\"ACCEPT\" | dstport!=\"443\" | dstport!=\"5432\" | dstport!=\"7844\" [1h]))"
        refId     = "loki_query"
        queryType = "range"
      })
    }

    data {
      ref_id         = "threshold"
      datasource_uid = "-100"

      relative_time_range {
        from = 0
        to   = 0
      }

      model = jsonencode({
        type       = "threshold"
        conditions = [{
          evaluator = { type = "gt", params = [50] }
          operator  = { type = "and" }
          query     = { params = ["loki_query"] }
          reducer   = { type = "last" }
        }]
        refId = "threshold"
      })
    }

    for                = "15m"
    no_data_state      = "OK"
    exec_err_state     = "Alerting"
    annotations = {
      summary     = "Unusual outbound traffic detected in ${var.environment}"
      description = "High volume of outbound traffic to non-standard ports. Investigate for potential data exfiltration or misconfigured services."
    }
    labels = {
      severity    = "critical"
      environment = var.environment
    }
  }
}


# ──────────────────────────────────────────────
# Grafana Alert Rules — Application Health
# ──────────────────────────────────────────────

resource "grafana_rule_group" "app_health_alerts" {
  name             = "Application Health"
  folder_uid       = grafana_folder.keystone.uid
  interval_seconds = 60

  # Alert: High 5xx error rate from application logs
  rule {
    name      = "High 5xx Error Rate"
    condition = "threshold"

    data {
      ref_id         = "loki_query"
      datasource_uid = var.grafana_loki_datasource_uid

      relative_time_range {
        from = 300
        to   = 0
      }

      model = jsonencode({
        expr      = "sum(rate({job=\"keystone-app\"} | json | status_code >= 500 [5m]))"
        refId     = "loki_query"
        queryType = "range"
      })
    }

    data {
      ref_id         = "threshold"
      datasource_uid = "-100"

      relative_time_range {
        from = 0
        to   = 0
      }

      model = jsonencode({
        type       = "threshold"
        conditions = [{
          evaluator = { type = "gt", params = [1] }
          operator  = { type = "and" }
          query     = { params = ["loki_query"] }
          reducer   = { type = "last" }
        }]
        refId = "threshold"
      })
    }

    for                = "5m"
    no_data_state      = "OK"
    exec_err_state     = "Alerting"
    annotations = {
      summary     = "High 5xx error rate in ${var.environment}"
      description = "Application is returning server errors at an elevated rate. Check application logs and database connectivity."
    }
    labels = {
      severity    = "critical"
      environment = var.environment
    }
  }
}
