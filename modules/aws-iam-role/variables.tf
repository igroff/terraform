variable "name" {
  type        = string
  description = "The name of the IAM role that is to be created."
}

variable "tags" {
  type        = map(string)
  description = "Tags to attach to the role"
}

variable "assume_role_policy" {
  type        = string
  description = "A JSON doc describing the policy controlling what resources may assume this role"
}

variable "path" {
  type        = string
  description = "IAM Role path, used to organize roles for an account"
  default     = "/"
}

variable "description" {
  type        = string
  description = "A description for the created IAM Role"
}

variable "attach_these_policies" {
  type        = map(string)
  description = "Additional policies to attach to the role"
}
