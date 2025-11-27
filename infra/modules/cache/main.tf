locals {
  name = "${var.project_name}-redis"
  redis_port = 6379
}

########################################
# Subnet Group (Private Only)
########################################
resource "aws_elasticache_subnet_group" "redis_subnets" {
  name       = "${local.name}-subnet-group"
  subnet_ids = var.private_subnets

  tags = {
    Name = "${local.name}-subnet-group"
  }
}

########################################
# Security Group (Allow only App SG)
########################################
resource "aws_security_group" "redis_sg" {
  name        = "${local.name}-sg"
  description = "Allow application to access Redis"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = local.redis_port
    to_port         = local.redis_port
    protocol        = "tcp"
    security_groups = [var.app_sg_id]   # 🔥 Only allow from compute
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

########################################
# Redis Cluster
########################################
resource "aws_elasticache_cluster" "redis" {
  cluster_id           = local.name
  engine               = "redis"
  node_type            = var.node_type
  num_cache_nodes      = var.num_cache_nodes

  port                 = local.redis_port
  subnet_group_name    = aws_elasticache_subnet_group.redis_subnets.name
  security_group_ids   = [aws_security_group.redis_sg.id]

  # parameter_group_name = "default.redis7"  
  tags = {
    Name = local.name
  }
}
