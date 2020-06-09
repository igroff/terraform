locals {
  region = "us-east-2"
  network_tag_base = {System = "rdnetinf"}
}
provider "aws" {
  region  = local.region
  profile = "ilegitcreator"
}

resource "aws_vpc" "primary" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true
  tags                 = merge({ Name = var.name_prefix }, var.base_tags, local.network_tag_base)
}
module "subnets" {
  source         = "../../modules/subnets-ue2"
  vpc_id         = aws_vpc.primary.id
  vpc_cidr_block = aws_vpc.primary.cidr_block
  name_prefix    = var.name_prefix
  tags           = merge(var.base_tags, local.network_tag_base)
}

module "network" {
  source                  = "../../modules/network/"
  name_prefix             = "c1-vpc"
  region                  = local.region
  vpc_id                  = aws_vpc.primary.id
  vpc_main_route_table_id = aws_vpc.primary.main_route_table_id

  public_subnet_1_id = module.subnets.public_subnet_1_id
  public_subnet_2_id = module.subnets.public_subnet_2_id
  public_subnet_3_id = module.subnets.public_subnet_3_id

  tags = merge(var.base_tags, local.network_tag_base)
}