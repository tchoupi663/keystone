generate_hcl "terragrunt.hcl" {
  condition = tm_contains(terramate.stack.tags, "child")
  content {
    include "root" {
      path = find_in_parent_folders("_tpl_terragrunt.hcl")
    }
  }
}

