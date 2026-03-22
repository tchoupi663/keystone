
region      = "eu-north-1"
environment = "dev"
project     = "keystone"

domain_name = "edenkeystone.com"
grafana_loki_host = "logs-prod-035.grafana.net"
grafana_loki_user = "1511095"


public_subnets_count   = 2
private_subnets_count  = 2
database_subnets_count = 2

listener_rules = {
  eden_keystone = {
    priority     = 100
    host_headers = ["demo.edenkeystone.com"]
  }
}