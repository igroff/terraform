variable "vpc_id" {
  type = string
}

variable "vpc_cidr_block" {
  type = string
}

variable "name_prefix" {
  type = string
}

variable "tags" {
  type = map(any)
  default = {}
}