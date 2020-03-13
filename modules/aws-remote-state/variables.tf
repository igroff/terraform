variable "aws_profile" {
  type        = string
  description = "The name of a named profile as configured for use with the awc-cli as discussed: https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-profiles.html"
}

variable "aws_region" {
  type        = string
  default     = "us-east-2"
  description = "The region in which the remote state resources will be created, us-east-1 is a common default so often over provisioned, so we conveniently default to us-east-2"
}

variable "s3_state_bucket" {
  type        = string
  description = "The name of the s3 bucke that will be created, this is where the tf state files will be stored."
}

variable "dynamo_lock_table" {
  type        = string
  default     = "terraform-state-locks"
  description = "This is the name of the dynamo table that will be created which will be used to lock state allowig for multiple users to coordinate terraform template execution."
}
