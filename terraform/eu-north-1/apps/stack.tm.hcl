stack {
  name        = "apps"
  description = "apps"
  tags        = ["parent", "apps"]
  after       = ["tag:infra"]
  id          = "a59cc57b-c3af-44b0-8107-108e5a58ae78"
}

globals {
  providers = ["aws"]
}