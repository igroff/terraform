variable "cluster_instance_type" {
  type    = string
  default = "t3a.micro"
}

variable "region" {
  type    = string
  default = "us-east-2"
}

variable "cluster_name" {
  type    = string
  default = "rdc1"
}

variable "container_port" {
  type        = number
  description = "The port on which the container listens for traffic."
}

variable "container_image" {
  type        = string
  description = "An image indicator, in any format supported by ECS taskdef"
}

variable "tags" {
  type = map(string)
  default = {}
}