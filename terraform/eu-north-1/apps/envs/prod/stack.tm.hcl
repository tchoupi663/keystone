stack {
  name        = "apps"
  description = "apps"
  tags        = ["apps-prod", "child", "prod", "apps"]
  after       = ["tag:infra"]
  id          = "be51de72-f415-4cf0-be83-d6a9aecc7f8d"
}
