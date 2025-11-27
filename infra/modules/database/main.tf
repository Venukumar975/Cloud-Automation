locals {
  name    = "${var.project_name}-db"
  db_port = var.engine == "mysql" ? 3306 : 5432
}

########################################
# DB Subnet Group (Private Only)
########################################
resource "aws_db_subnet_group" "db_subnets" {
  name       = "${local.name}-subnet-group"
  subnet_ids = var.private_subnets

  tags = {
    Name = "${local.name}-subnet-group"
  }
}

########################################
# Security Group (Allow only App SG)
########################################
resource "aws_security_group" "db_sg" {
  name        = "${local.name}-sg"
  description = "Allow app servers to reach DB"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = local.db_port
    to_port         = local.db_port
    protocol        = "tcp"
    security_groups = [var.app_sg_id]   # 🔥 Only allow from Compute instances
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

########################################
# Generate Password & Store in SSM
########################################
resource "random_password" "db_pass" {
  length = 20
  special          = true
  override_special = "!#$%^&*()-_=+[]{}<>.?"
}

resource "aws_ssm_parameter" "db_password" {
  name  = "/${var.project_name}/db/password"
  type  = "SecureString"
  value = random_password.db_pass.result
}

########################################
# Create DB Instance
########################################
resource "aws_db_instance" "db" {
  identifier              = local.name
  engine                  = var.engine
  engine_version          = var.engine_version
  instance_class          = var.instance_class
  allocated_storage       = var.storage_gb

  username                = "db_admin"
  password                = random_password.db_pass.result
  port                    = local.db_port

  db_subnet_group_name    = aws_db_subnet_group.db_subnets.name
  vpc_security_group_ids  = [aws_security_group.db_sg.id]

  multi_az                = var.multi_az
  publicly_accessible     = var.publicly_accessible
  skip_final_snapshot     = true

  storage_encrypted       = true
  backup_retention_period = var.multi_az ? 7 : 1 

  tags = {
    Name = local.name
  }
}
