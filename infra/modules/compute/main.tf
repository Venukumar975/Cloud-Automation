locals {
  name = var.project_name
}

###############################################
#               AMI (Ubuntu 20.04)
###############################################
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

###############################################
#             SECURITY GROUPS
###############################################
resource "aws_security_group" "alb_sg" {
  name        = "${local.name}-alb-sg"
  description = "Allow inbound HTTP"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "app_sg" {
  name        = "${local.name}-app-sg"
  description = "Allow ALB traffic to app instances"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

###############################################
#               LAUNCH TEMPLATE
###############################################
resource "aws_launch_template" "app" {
  name_prefix   = "${local.name}-lt"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  monitoring {
    enabled = true
  }
  vpc_security_group_ids = [
    aws_security_group.app_sg.id
  ]

  iam_instance_profile {
    name = var.instance_profile_name
  }
   # 🔴 ADD THIS BLOCK TO PREVENT ZOMBIE VOLUMES
  block_device_mappings {
    device_name = "/dev/sda1" # Standard Ubuntu root device
    ebs {
      volume_size           = 8
      volume_type           = "gp3"
      delete_on_termination = true  # <--- THIS SAVES YOU MONEY
    }
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    project_name  = var.project_name
    service_name  = var.service_name
    app_port      = var.app_port
    health_path   = var.health_check_path
    region        = var.region
  }))
}

###############################################
#           LOAD BALANCER + TARGET GROUP
###############################################
resource "aws_lb_target_group" "app_tg" {
  name     = "${local.name}-tg"
  port     = var.app_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = var.health_check_path
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-399"
  }
}

resource "aws_lb" "app_alb" {
  name               = "${local.name}-alb"
  load_balancer_type = "application"
  subnets            = var.public_subnets
  security_groups    = [aws_security_group.alb_sg.id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

###############################################
#           AUTO SCALING GROUP
###############################################
resource "aws_autoscaling_group" "app_asg" {
  name                = "${local.name}-asg"
  desired_capacity    = var.desired_capacity
  max_size            = var.max_size
  min_size            = var.min_size
  vpc_zone_identifier = var.private_subnets

  launch_template {
    id      = aws_launch_template.app.id
    version = aws_launch_template.app.latest_version
  }
  target_group_arns = [aws_lb_target_group.app_tg.arn]
  health_check_type = "ELB"
  health_check_grace_period = 120
  default_cooldown = 150
  default_instance_warmup = 120

  termination_policies = ["OldestInstance"]

  # --- NEW: WARM POOL CONFIGURATION ---
  warm_pool {
    pool_state                  = var.warm_pool_state # Saves money (Paying for EBS only)
    min_size                    = var.warm_pool_min_size      # Always keep 3 ready for spikes
    max_group_prepared_capacity = 3
    
    instance_reuse_policy {
      reuse_on_scale_in = true # Return instances to pool instead of terminating
    }
  }

  instance_refresh {
    strategy = "Rolling"

    preferences {
      min_healthy_percentage = 80
      instance_warmup        = 120
    }

    triggers = []
  }

  tag {
    key                 = "Name"
    value               = "${local.name}-app"
    propagate_at_launch = true
  }

  # Prevent TF from undoing emergency fixes
  lifecycle {
    ignore_changes = [
      min_size,
      max_size,
      desired_capacity
    ]
  }
}

# =========================================================
# POLICY 1: Target Tracking (Cruising at 50% CPU)
# =========================================================
# 🔹 Target Tracking Scaling Policy (CPU-based)
resource "aws_autoscaling_policy" "cpu_target_tracking" {
  name                   = "${local.name}-cpu-target-tracking"
  autoscaling_group_name = aws_autoscaling_group.app_asg.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    # Target average CPU %
    target_value = 50

    # Optional fine-tuning
    disable_scale_in = true
  }
}

# =========================================================
# POLICY 2: Emergency Step Scaling (Scale OUT > 95%)
# =========================================================
resource "aws_cloudwatch_metric_alarm" "cpu_high_emergency" {
  alarm_name          = "${local.name}-cpu-high-emergency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1      # React fast (1 minute)
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = var.emergency_cpu_threshold     # Trigger at 95%

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app_asg.name
  }

  alarm_description = "Emergency Scale Out if CPU > 95%"
  alarm_actions     = [aws_autoscaling_policy.emergency_scale_out.arn]
}

resource "aws_autoscaling_policy" "emergency_scale_out" {
  name                   = "${local.name}-emergency-scale-out"
  autoscaling_group_name = aws_autoscaling_group.app_asg.name
  policy_type            = "StepScaling"
  adjustment_type        = "ChangeInCapacity" # Add absolute numbers (not percent)

  step_adjustment {
    scaling_adjustment          = 2 # Add 2 instances immediately
    metric_interval_lower_bound = 0 # From 95% upwards
  }
}

# =========================================================
# POLICY 3: Aggressive Scale In (Scale IN < 20%)
# =========================================================

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "${local.name}-cpu-low-alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 2   # Requested: 2 eval periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60  # Requested: 1 minute period
  statistic           = "Average"
  threshold           = 20  # Assuming 20% CPU is the trigger to scale in (adjust as needed)

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app_asg.name
  }

  alarm_description = "Scale in if CPU < 20% for 2 minutes"
  alarm_actions     = [aws_autoscaling_policy.scale_in.arn]
}

# 🔹 Simple Scale In Policy (step scaling)
resource "aws_autoscaling_policy" "scale_in" {
  name                   = "${local.name}-scale-in"
  autoscaling_group_name = aws_autoscaling_group.app_asg.name
  policy_type            = "StepScaling"
  adjustment_type        = "PercentChangeInCapacity"
  step_adjustment {
    scaling_adjustment          = -50
    metric_interval_upper_bound = 0 # Applies when the metric is below the alarm threshold
  }
}



resource "aws_ssm_parameter" "launch_template_id" {
  name           = "/${var.project_name}/compute/${var.service_name}/launch_template_id"
  type           = "String"
  insecure_value = aws_launch_template.app.id
}

resource "aws_ssm_parameter" "container_port" {
  name  = "/${var.project_name}/compute/${var.service_name}/port"
  type  = "String"
  value = var.container_port
}

resource "aws_ssm_parameter" "image_tag" {
  name  = "/${var.project_name}/compute/${var.service_name}/image_tag"
  type  = "String"
  value = "latest"
}

resource "aws_ssm_parameter" "image_uri" {
  name  = "/${var.project_name}/compute/${var.service_name}/image_uri"
  type  = "String"
  value = "dummy"
}

resource "aws_ssm_parameter" "asg_name" {
  name  = "/${var.project_name}/compute/${var.service_name}/asg_name"
  type  = "String"
  value = aws_autoscaling_group.app_asg.name
}
