variable "project_name" {
  type = string
}

variable "github_owner" {
  type        = string
  description = "GitHub organization or user name"
}

variable "github_repo" {
  type        = string
  description = "Repository name for CI/CD trust restriction"
}
