output "alb_dns" {
  value = aws_lb.app_alb.dns_name
}

output "app_sg_id" {
  value = aws_security_group.app_sg.id
}

output "target_group_arn" {
  value = aws_lb_target_group.app_tg.arn
}

output "asg_name" {
  value = aws_autoscaling_group.app_asg.name
}

output "scale_out_policy_arn" {
  value = aws_autoscaling_policy.cpu_target_tracking.arn
}

output "scale_in_policy_arn" {
  value = aws_autoscaling_policy.cpu_target_tracking.arn
}
