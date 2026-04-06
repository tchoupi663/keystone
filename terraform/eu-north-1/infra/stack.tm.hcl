stack {
  name        = "infra"
  description = "infra-source"
  tags        = ["parent", "infra-parent", "observability-data"]
  after       = ["tag:network"]
  id          = "96b11354-f926-40cb-96ed-56f4730eb672"
}

globals {
  providers = ["aws"]
}
