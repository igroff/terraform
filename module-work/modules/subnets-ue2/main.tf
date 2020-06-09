resource "aws_subnet" "subnet-1_public" {
  vpc_id            = var.vpc_id
  cidr_block        = cidrsubnet(var.vpc_cidr_block, 4, 3)
  availability_zone = "us-east-2a"

  tags = merge({ Name = "${var.name_prefix}-subnet-1_public", Type = "Public" }, var.tags)
}
resource "aws_subnet" "subnet-2_public" {
  vpc_id            = var.vpc_id
  cidr_block        = cidrsubnet(var.vpc_cidr_block, 4, 4)
  availability_zone = "us-east-2b"

  tags = merge({ Name = "${var.name_prefix}-subnet-2_public", Type = "Public" }, var.tags)
}

resource "aws_subnet" "subnet-3_public" {
  vpc_id            = var.vpc_id
  cidr_block        = cidrsubnet(var.vpc_cidr_block, 4, 5)
  availability_zone = "us-east-2c"

  tags = merge({ Name = "${var.name_prefix}-subnet-3_public", Type = "Public" }, var.tags)
}

data "aws_subnet_ids" "public_subnet_ids" {
  vpc_id = var.vpc_id
  tags   = merge({ Type = "Public" }, var.tags)
  # so, I can't find anything that indicates this is necessary BUT
  # if you don't have the depdnencies here this data element gets created (or can be created) 
  # before any of the subnets which results in failure for all the things depending on this 
  # data element
  depends_on = [
    aws_subnet.subnet-1_public,
    aws_subnet.subnet-2_public,
    aws_subnet.subnet-3_public,
  ]
}