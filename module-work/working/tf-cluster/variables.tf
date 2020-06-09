variable "base_tags" {
  type = map(any)
  default = {
    Owner = "me"
    System = "rdnetinf"
  }
}