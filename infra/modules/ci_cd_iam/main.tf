locals {
  name = "${var.project_name}-cicd"
}

# Get AWS Account ID
data "aws_caller_identity" "current" {}

# ---------------------------
#  GitHub OIDC Provider
# ---------------------------
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1"
  ]
}

# ---------------------------
#  Role for GitHub Actions
# ---------------------------
resource "aws_iam_role" "github_actions" {
  name = "${local.name}-github-role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringLike = {
            # IMPORTANT: Restrict to your repo
            "token.actions.githubusercontent.com:sub" = "repo:${var.owner}/${var.repo}:*"
          },
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

# ---------------------------
#  IAM Policy for CI/CD
# ---------------------------
resource "aws_iam_policy" "github_actions_policy" {
  name = "${local.name}-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [

      #######################################################################
      # ECR Permissions
      #######################################################################
      {
        Effect = "Allow",
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage"
        ],
        Resource = "*"
      },

      #######################################################################
      # Auto Scaling Actions (FULL FIX)
      #######################################################################
      {
        Effect = "Allow",
        Action = [
          "autoscaling:StartInstanceRefresh",
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeInstanceRefreshes"   # <--- REQUIRED
        ],
        Resource = "*"
      },

      #######################################################################
      # S3 Deploy (Frontend)
      #######################################################################
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:DeleteObject",
          "s3:ListBucket"
        ],
        Resource = "*"
      },

      #######################################################################
      # CloudFront Invalidations (Frontend Deploy)
      #######################################################################
      {
        Effect = "Allow",
        Action = [
          "cloudfront:CreateInvalidation"
        ],
        Resource = "*"
      },

      #######################################################################
      # SSM PARAMETER STORE — READ/WRITE
      #######################################################################

      # Backend CI writes: /<project_name>/compute/*
      {
        Effect = "Allow",
        Action = [
          "ssm:PutParameter",
          "ssm:GetParameter"
        ],
        Resource = "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/${var.project_name}/compute/*"
      },

      # Allow CI & Deploy to read backend & frontend
      {
        Effect = "Allow",
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParameterHistory",
          "ssm:GetParametersByPath"
        ],
        Resource = [
          "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/${var.project_name}/compute/*",
          "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/${var.project_name}/frontend/*",
          "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/${var.project_name}/backend",
          "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/${var.project_name}/backend/*"
        ]
      }

    ]
  })
}

# ---------------------------
# Attach Policy to Role
# ---------------------------
resource "aws_iam_role_policy_attachment" "github_attach" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions_policy.arn
}
