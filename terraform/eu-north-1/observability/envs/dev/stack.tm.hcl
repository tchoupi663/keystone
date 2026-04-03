stack {
  name        = "dev"
  description = "dev"
  tags        = ["child", "observability"]
  after       = ["/terraform/eu-north-1/apps/envs/dev"]
  id          = "b46522de-c565-45f9-b353-b39ff121f37d"
}
