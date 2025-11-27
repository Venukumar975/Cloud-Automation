variable "project_name" { type = string }
variable "vpc_id"       { type = string }

variable "public_subnets"  { type = list(string) }
variable "private_subnets" { type = list(string) }

variable "instance_type" { type = string }
variable "app_port"      { type = number }

variable "min_size"         { type = number }
variable "max_size"         { type = number }
variable "desired_capacity" { type = number }

variable "instance_profile_name" {
  type = string
}

variable "ami_id" {
  type        = string
  default     = ""
}

variable "health_check_path" {
  type    = string
  default = "/"
}

variable "health_check_interval" {
  type    = number
  default = 30
}
