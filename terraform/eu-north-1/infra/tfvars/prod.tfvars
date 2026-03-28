region      = "eu-north-1"
environment = "prod"
project     = "keystone"

grafana_loki_host = "logs-prod-035.grafana.net"
grafana_loki_user = "1511095"

# Production uses more redundancy
public_subnets_count   = 3
private_subnets_count  = 3
database_subnets_count = 3
