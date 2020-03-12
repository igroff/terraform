provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}


resource "aws_s3_bucket" "terraform_state" {
  bucket = var.s3_state_bucket

  # Prevent accidental deletion of this S3 bucket
  lifecycle {
    prevent_destroy = false
  }

  # Enable versioning so we can see the full revision history of our
  # state files
  versioning {
    enabled = true
  }

  # Enable server-side encryption by default
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = var.dynamo_lock_table
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

resource "aws_iam_user" "terraform_state_user" {
  name = "terraform-state-user"
  path = "/system/"
}

resource "aws_iam_user_policy" "terraform_state_policy" {
  name = "terraform-state-policy"
  user = aws_iam_user.terraform_state_user.name

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "dynamodb:PutItem",
                "dynamodb:DescribeTable",
                "dynamodb:DeleteItem",
                "dynamodb:GetItem",
                "s3:ListBucket",
                "s3:GetBucketVersioning"
            ],
            "Resource": [
                "arn:aws:dynamodb:*:*:table/${var.dynamo_lock_table}",
                "arn:aws:s3:::${var.s3_state_bucket}",
                "arn:aws:s3:::${var.s3_state_bucket}/*"
            ]
        }
    ]
}
EOF
}
