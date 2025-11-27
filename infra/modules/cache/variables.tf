variable "project_name"      { type = string }
variable "private_subnets"   { type = list(string) }
variable "vpc_id"            { type = string }
variable "app_sg_id"         { type = string }

variable "node_type"         { type = string }
variable "num_cache_nodes"   { type = number }
