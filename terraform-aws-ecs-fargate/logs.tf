resource "aws_cloudwatch_log_group" "django" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = 7  
}
