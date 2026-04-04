logging {
  level  = "debug"
  format = "logfmt"
}

prometheus.scrape "flask_app" {
  targets = [
    {"__address__" = "localhost:${container_port}"},
  ]
  forward_to = [prometheus.remote_write.grafana_cloud.receiver]
  scrape_interval = "60s"
}

prometheus.remote_write "grafana_cloud" {
  endpoint {
    url = "${grafana_prometheus_url}"
    basic_auth {
      username = "${grafana_prometheus_user}"
      password = coalesce(sys.env("GRAFANA_API_KEY"), "missing")
    }
    
    queue_config {
      max_samples_per_send = 1000
      batch_send_deadline  = "30s"
    }
  }
}

otelcol.receiver.otlp "otlp_receiver" {
  grpc {
    endpoint = "127.0.0.1:4317"
  }
  http {
    endpoint = "127.0.0.1:4318"
  }

  output {
    traces = [otelcol.processor.transform.add_peer_service.input]
    logs   = [otelcol.exporter.loki.grafanacloud.input]
  }
}

otelcol.processor.transform "add_peer_service" {
  error_mode = "ignore"
  trace_statements {
    context = "span"
    statements = [
      "set(span.attributes[\"peer.service\"], span.attributes[\"db.system\"]) where span.attributes[\"peer.service\"] == nil and span.attributes[\"db.system\"] != nil",
    ]
  }
  output {
    traces = [
      otelcol.exporter.otlp.grafanacloud.input,
      otelcol.connector.servicegraph.default.input,
    ]
  }
}

loki.write "grafanacloud" {
  endpoint {
    url = "https://${grafana_loki_host}/loki/api/v1/push"
    basic_auth {
      username = "${grafana_loki_user}"
      password = coalesce(sys.env("GRAFANA_API_KEY"), "missing")
    }
  }
  external_labels = {
    job = "keystone-app",
    env = "${environment}",
  }
}

otelcol.exporter.loki "grafanacloud" {
  forward_to = [loki.write.grafanacloud.receiver]
}

otelcol.connector.servicegraph "default" {
  dimensions = ["http.method", "http.target"]
  output {
    metrics = [otelcol.exporter.prometheus.servicegraphs.input]
  }
}

otelcol.exporter.prometheus "servicegraphs" {
  forward_to = [prometheus.remote_write.grafana_cloud.receiver]
  add_metric_suffixes = false
}

otelcol.exporter.otlp "grafanacloud" {
  client {
    endpoint = "${grafana_tempo_endpoint}"
    auth     = otelcol.auth.basic.grafanacloud.handler
  }
}

otelcol.auth.basic "grafanacloud" {
  username = "${grafana_tempo_user}"
  password = coalesce(sys.env("GRAFANA_API_KEY"), "missing")
}
