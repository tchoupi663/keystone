stack {
  name        = "infra"
  description = "infra"
  tags        = ["child", "infra-prod", "prod", "infra"]
  after       = ["tag:network"] 
  id          = "f7d8e3d1-ebe7-45c3-ac76-4aac3a231d39"
}
