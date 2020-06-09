output "public_subnet_ids" {
  value = data.aws_subnet_ids.public_subnet_ids.ids
}

output "public_subnet_1_id" {
  value = aws_subnet.subnet-1_public.id
}
output "public_subnet_2_id" {
  value = aws_subnet.subnet-2_public.id
}
output "public_subnet_3_id" {
  value = aws_subnet.subnet-3_public.id
}