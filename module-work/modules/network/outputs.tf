

output "ssh_only_security_group" {
  value = aws_security_group.ssh_only.id
}