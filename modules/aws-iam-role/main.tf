resource "aws_iam_role" "role" {
  name               = var.name
  assume_role_policy = var.assume_role_policy
  path               = var.path
  description        = var.description
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "aws_iam_role_policy_attachments" {
  for_each = var.attach_these_policies

  role       = aws_iam_role.role.name
  policy_arn = each.value
}