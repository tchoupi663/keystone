generate_hcl "_backend.tf" {
  condition = tm_contains(terramate.stack.tags, "parent")
  content {
    terraform {
      backend "s3" {
        bucket               = "keystone-infra-terraform-state"
        key                  = "${terramate.stack.name}/${global.region}/${terramate.stack.name}.tfstate"
        region               = global.region
        use_lockfile         = true
        encrypt              = true
      }
    }
  }
}