generate_file "_versions.tf" {
  condition = tm_contains(terramate.stack.tags, "parent")
  content   = <<-EOF
// TERRAMATE GENERATED FILE - DO NOT EDIT

terraform {
  required_version = ">= 1.5.0, < 2.0.0"
  required_providers {
  %{ for p in global.providers ~}
  ${p} = {
      source  = "${global.provider_configs[p].source}"
      version = "${global.provider_configs[p].version}"
    }
  %{ endfor ~}
}
}
EOF
}
