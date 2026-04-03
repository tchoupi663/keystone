stack {
  name        = "observability"
  description = "observability"
  tags        = ["parent", "observability"]
  after       = ["tag:infra", "tag:apps"]
  id          = "11b2ae21-0e8a-48a6-a9e7-c60c4d2329c8"
}

globals {
  providers = ["aws", "grafana"]
}
