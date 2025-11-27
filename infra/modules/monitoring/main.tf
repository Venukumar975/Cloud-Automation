locals {
  name = "${var.project_name}-monitoring"
}

#######################################
# CloudWatch Log Group for application
#######################################
resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/${var.project_name}/app"
  retention_in_days = 30

  tags = {
    Project = var.project_name
  }
}

#######################################
# CloudWatch Metrics for Autoscaling
#######################################
# 🔼 Scale Up (High CPU)
resource "aws_cloudwatch_metric_alarm" "scale_up" {
  alarm_name          = "${var.project_name}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 75
  alarm_description   = "High CPU, scale out"
  dimensions = {
    AutoScalingGroupName = var.asg_name
  }

  alarm_actions = [var.asg_policy_scale_out_arn]
}

# 🔽 Scale Down (Low CPU)
resource "aws_cloudwatch_metric_alarm" "scale_down" {
  alarm_name          = "${var.project_name}-low-cpu"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 15
  alarm_description   = "Low CPU, scale in"
  dimensions = {
    AutoScalingGroupName = var.asg_name
  }

  alarm_actions = [var.asg_policy_scale_in_arn]
}

#######################################
# Export Log Group Name (used inside EC2 user data)
#######################################
output "app_log_group" {
  value = aws_cloudwatch_log_group.app_logs.name
}
