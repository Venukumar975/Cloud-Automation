variable "project_name" { type = string }
variable "vpc_id"       { type = string }
variable "region" {type = string}

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

variable "service_name" {
  description = "Name of the backend service"
  type        = string
}

variable "container_port" {
  description = "Port the backend app listens on"
  type        = number
  default = 3000
}

# Added for warm pool setup
variable "warm_pool_min_size" {
  description = "Minimum number of instances to keep in the Warm Pool"
  type        = number
  default     = 0
}



variable "warm_pool_state" {
  description = "State of warm pool instances (Stopped or Running)"
  type        = string
  default     = "Stopped"
}

variable "emergency_cpu_threshold" {
  description = "CPU % threshold to trigger emergency scaling"
  type        = number
  default     = 95
}