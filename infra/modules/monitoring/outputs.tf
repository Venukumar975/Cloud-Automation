output "log_group_path" {
  value = aws_cloudwatch_log_group.app_logs.name
}
