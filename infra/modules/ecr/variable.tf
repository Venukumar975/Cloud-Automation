variable "project_name" { type = string }
variable "environment"  { type = string }

# backend service identifiers (e.g., api, auth, users)
variable "services" {
  type        = list(string)
  description = "Backend service names for ECR repositories"
}
