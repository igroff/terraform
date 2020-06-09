variable "region" {
  type    = string
  default = "us-west-2"
}

variable "name_prefix" {
  type    = string
  default = "primary-vpc"
}

variable "vpc_id" {
  type = string
}

variable "vpc_cidr_block" {
  type    = string
  default = "192.168.0.0/16"
}

variable "public_subnet_1_id" {
  type = string
}
variable "public_subnet_2_id" {
  type = string
}
variable "public_subnet_3_id" {
  type = string
}

variable "vpc_main_route_table_id" {
  type = string
}

variable "tags" {
  type = map(any)
  default = {}
}