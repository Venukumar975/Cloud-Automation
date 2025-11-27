locals {
  name = var.project_name
}

####################################
# IAM Role for EC2 (SSM + Logs)
####################################
resource "aws_iam_role" "ssm_role" {
  name = "${local.name}-ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

####################################
# Core Required Policies
####################################
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cw_logs" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

####################################
# Custom policy to read only project secrets
####################################
resource "aws_iam_role_policy" "ssm_parameter_access" {
  name = "${local.name}-ssm-parameter-policy"
  role = aws_iam_role.ssm_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "ssm:GetParameter",
        "ssm:GetParameters",
        "ssm:GetParametersByPath"
      ],
      Resource = "arn:aws:ssm:*:*:parameter/${local.name}/*"
    }]
  })
}

####################################
# Instance Profile
####################################
resource "aws_iam_instance_profile" "ssm_profile" {
  name = "${local.name}-ec2-ssm-profile"
  role = aws_iam_role.ssm_role.name
}
