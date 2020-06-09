terraform {
  backend "s3" {
    bucket   = "com.intimidatingbits.igstate"
    key      = "rd/ohio/regional/rd-cluster/not-different"
    region   = "us-east-1"
    role_arn = "arn:aws:iam::652010561193:role/tf-state-management-role"

    dynamodb_table = "terraform-state-locks"
    encrypt        = true
    profile        = "ilegitcreator"
  }
}