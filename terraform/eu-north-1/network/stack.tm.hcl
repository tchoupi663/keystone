stack {
  name        = "network"
  description = "network"
  tags        = ["parent", "network-parent"]
  before      = ["tag:infra"]
  id          = "430d090d-f338-462c-925c-691dd20e9460"
}

globals {
  providers = ["aws", "cloudflare", "random"]
}