terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
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

resource "aws_iam_user" "main" {
  for_each = toset(local.user_data[*].username)
  name     = each.value
}