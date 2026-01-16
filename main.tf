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

  user_role_pair = flatten([ for user in local.user_data : [ for role in user.role : {
    username = user.username
    role     = role
  } ]])
}

output "name" {
  value = local.user_role_pair
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

resource "aws_iam_user_policy_attachment" "main" {
  for_each = {
    for pair in local.user_role_pair : "${pair.username}-${pair.role}" => pair 
  }

  user = aws_iam_user.users[each.value.username].name
  policy_arn = "arn:aws:iam::aws:policy/${each.value.role}"
}
