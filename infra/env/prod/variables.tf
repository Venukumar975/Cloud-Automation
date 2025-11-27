# Core
variable "project_name" { type = string }
variable "region" { type = string }
variable "vpc_cidr" { type = string }
variable "availability_zones" { type = list(string) }
variable "public_subnets" { type = list(string) }
variable "private_subnets" { type = list(string) }
variable "nat_gateway" { type = bool }

# Compute / App
variable "instance_type" { type = string }
variable "app_port"      { type = number }
variable "min_instances" { type = number }
variable "max_instances" { type = number }
variable "desired_instances" { type = number }

# Database Flags
variable "enable_rds" { type = bool }
variable "db_engine" { type = string }
variable "db_version" { type = string }
variable "db_instance_class" { type = string }
variable "db_storage" { type = number }
variable "db_multi_az" { type = bool }
variable "db_public" { type = bool }
variable "multi_az" { type = bool }
# Cache Flags
variable "enable_redis" { type = bool }
variable "cache_node_type" { type = string }
variable "cache_num_nodes" { type = number }
# frontend flags
variable "frontend_enabled" { type = bool }
 
