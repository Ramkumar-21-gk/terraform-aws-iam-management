terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.28.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

locals {
  user_data = yamldecode(file("./users.yaml")).users
}

output "name" {
  value = local.user_data[*].username
}

resource "aws_iam_user" "users" {
  for_each = toset(local.user_data[*].username)
  name     = each.value
}

resource "aws_iam_user_login_profile" "example" {
  for_each        = aws_iam_user.users
  user            = each.value.name
  password_length = 16

  lifecycle {
    ignore_changes = [
      password_length,
      password_reset_required,
      pgp_key,
    ]
  }
}

data "aws_caller_identity" "current" {}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}
