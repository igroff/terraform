variable "region" {
  type    = string
  default = "us-west-2"
}

variable "name_prefix" {
  type    = string
  default = "primary-vpc"
}

variable "vpc_cidr_block" {
  type    = string
  default = "192.168.0.0/16"
}

variable "base_tags" {
  type = map(any)
  default = {
    Owner = "me"
  }
}