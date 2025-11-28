variable "project_name" {
  type = string
}

variable "owner" {
  type        = string
  description = "GitHub organization or user name"
}

variable "repo" {
  type        = string
  description = "Repository name for CI/CD trust restriction"
}
