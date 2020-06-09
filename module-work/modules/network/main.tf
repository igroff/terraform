resource "aws_internet_gateway" "primary_ig" {
  vpc_id = var.vpc_id
  tags = merge({ Name = "${var.name_prefix}-ig" }, var.tags)
}

resource "aws_security_group" "ssh_only" {
  name        = "SSH - Public"
  description = "Allow Port 22 traffic from EVERYWHERE"
  vpc_id      = var.vpc_id

  ingress {
    description = "Port 22 From Everywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags

}

resource "aws_security_group" "allow_tls" {
  name        = "Allow TLS"
  description = "Allow TLS inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

resource "aws_route_table" "public_subnet" {
  vpc_id = var.vpc_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.primary_ig.id
  }
  tags = merge({ Name = join("-", [var.name_prefix, "public-subnets"]) }, var.tags)
}

resource "aws_route_table_association" "public_subnet-4" {
  route_table_id = aws_route_table.public_subnet.id
  subnet_id      = var.public_subnet_1_id
}

resource "aws_route_table_association" "public_subnet-5" {
  route_table_id = aws_route_table.public_subnet.id
  subnet_id      = var.public_subnet_2_id
}

resource "aws_route_table_association" "public_subnet-6" {
  route_table_id = aws_route_table.public_subnet.id
  subnet_id      = var.public_subnet_3_id
}