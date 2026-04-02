stack {
  name        = "dev"
  description = "dev"
  tags        = ["child"]
  after       = ["/terraform/eu-north-1/infra/envs/dev"]
  id          = "f6633395-c5ed-46d1-9690-6e9ad08c2d49"
}
