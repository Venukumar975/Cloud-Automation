variable "project_name"      { type = string }
variable "private_subnets"   { type = list(string) }
variable "vpc_id"            { type = string }
variable "app_sg_id"         { type = string }  # 🔥 from compute module

variable "engine"            { type = string }   # postgres / mysql
variable "engine_version"    { type = string }
variable "instance_class"    { type = string }
variable "storage_gb"        { type = number }

variable "multi_az"          { type = bool }
variable "publicly_accessible" { type = bool }
