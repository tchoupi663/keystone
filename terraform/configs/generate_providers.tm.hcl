generate_file "_providers.tf" {
  condition = tm_contains(terramate.stack.tags, "parent")
  content   = <<-EOF
// TERRAMATE: GENERATED AUTOMATICALLY DO NOT EDIT

%{ for p in global.providers ~}
provider "${p}" {
%{ if p == "aws" ~}
  region = "${global.region}"
%{ endif ~}
%{ if p == "grafana" ~}
  url  = var.grafana_url
  auth = var.grafana_auth
%{ endif ~}
}
%{ endfor ~}
EOF
}
