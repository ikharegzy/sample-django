variable "aws_region" { default = "us-east-1" }
variable "project_name" { default = "sample-django" }
variable "image_uri" { description = "ECR image URI" }
variable "db_password" { sensitive = true }
