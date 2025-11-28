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
  description = "Allow ALB → instances"
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

  vpc_security_group_ids = [
    aws_security_group.app_sg.id
  ]

  iam_instance_profile {
    name = var.instance_profile_name
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
    healthy_threshold   = 3
    unhealthy_threshold = 3
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
  vpc_zone_identifier = var.private_subnets

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  health_check_type         = "ELB"
  health_check_grace_period = 600

  termination_policies = ["OldestInstance"]

  target_group_arns = [aws_lb_target_group.app_tg.arn]

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"

    preferences {
      min_healthy_percentage = 50
      instance_warmup        = 600
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

###############################################
#              SCALING POLICIES
###############################################
resource "aws_autoscaling_policy" "scale_out" {
  name                   = "${local.name}-scale-out"
  autoscaling_group_name = aws_autoscaling_group.app_asg.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 60
}

resource "aws_autoscaling_policy" "scale_in" {
  name                   = "${local.name}-scale-in"
  autoscaling_group_name = aws_autoscaling_group.app_asg.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = 60
}

resource "aws_autoscaling_policy" "cpu_target_tracking" {
  name                   = "${local.name}-cpu-tracking"
  autoscaling_group_name = aws_autoscaling_group.app_asg.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value     = 50
    disable_scale_in = false
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
