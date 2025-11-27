locals {
  project = var.project_name
}

resource "aws_ecr_repository" "repo" {
  for_each = toset(var.services)

  name = "${local.project}-backend-${each.value}"

  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}

# Write each repo URL to SSM
resource "aws_ssm_parameter" "ecr_repo" {
  for_each       = aws_ecr_repository.repo
  name           = "/${var.project_name}/ci/ecr/${each.key}/repo"
  type           = "String"
  insecure_value = each.value.repository_url
}


