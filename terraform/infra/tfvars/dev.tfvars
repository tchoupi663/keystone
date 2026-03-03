
region      = "eu-north-1"
environment = "dev"
project     = "keystone"

domain_name = "edenkeystone.com"

listener_rules = {
  eden_keystone = {
    priority     = 100
    host_headers = ["demo.edenkeystone.com"]
  }
}
