locals {
  region = "us-east-2"
}
provider "aws" {
  region  = local.region
  profile = "ilegitcreator"
}

module "cluster" {
  source                = "../../modules/ecs-cluster"
  cluster_instance_type = "t3a.micro"
  region                = local.region
  cluster_name          = "a-test-cluster"
  container_port        = 3333
  container_image       = "igroff/py27echo:latest-port-3333"
  tags                  = var.base_tags
}

output "cluster-lb-dns" {
  value = module.cluster.lb_dns_name
}