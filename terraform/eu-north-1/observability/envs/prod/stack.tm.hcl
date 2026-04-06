stack {
  name        = "observability"
  description = "observability"
  tags        = ["child", "observability", "prod"]
  after       = ["tag:apps"]
  id          = "6c13b769-4b85-477d-8230-ad3bdd5de229"
}
