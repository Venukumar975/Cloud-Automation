output "app_sg_id" {
  description = "Security group of app EC2/ASG"
  value       = aws_security_group.app_sg.id
}

output "asg_name" {
  description = "Name of app Auto Scaling Group"
  value       = aws_autoscaling_group.app_asg.name
}

# --- RENAMED FOR CLARITY ---
output "target_tracking_policy_arn" {
  description = "ARN of the Target Tracking Policy (50% CPU)"
  value       = aws_autoscaling_policy.cpu_target_tracking.arn
}

# --- NEW OUTPUT ---
output "emergency_scale_out_policy_arn" {
  description = "ARN of the Emergency Step Scaling Policy (>85% CPU)"
  value       = aws_autoscaling_policy.emergency_scale_out.arn
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
