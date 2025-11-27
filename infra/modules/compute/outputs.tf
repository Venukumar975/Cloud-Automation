output "app_sg_id" {
  description = "Security group of app EC2/ASG"
  value       = aws_security_group.app_sg.id
}

output "asg_name" {
  description = "Name of app Auto Scaling Group"
  value       = aws_autoscaling_group.app_asg.name
}

output "scale_out_policy_arn" {
  description = "Scale Out Policy ARN"
  value       = aws_autoscaling_policy.scale_out.arn
}

output "scale_in_policy_arn" {
  description = "Scale In Policy ARN"
  value       = aws_autoscaling_policy.scale_in.arn
}

output "launch_template_id" {
  description = "Launch Template ID used by ASG"
  value       = aws_launch_template.app.id
}

output "alb_dns" {
  description = "Public DNS of Application ALB"
  value       = aws_lb.app_alb.dns_name
}
