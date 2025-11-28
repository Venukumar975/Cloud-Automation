output "vpc_id" {
  value = module.vpc.vpc_id
}

output "alb_dns" {
  value = module.compute.alb_dns
}

output "instance_profile_name" {
  value = module.ssm_iam.instance_profile_name
}


output "db_endpoint" {
  value = try(module.database[0].db_endpoint, "")
}

output "redis_endpoint" {
  value = try(module.cache[0].redis_endpoint, "")
}

output "cloudfront_url" {
  value = try(module.frontend[0].cloudfront_url, "")
}

output "frontend_bucket" {
  value = try(module.frontend[0].bucket_name, "")
}

output "cloudwatch_logs" {
  value = module.monitoring.log_group_path
}

output "ecr_repos" {
  value = module.ecr.ecr_repo_urls
}

output "cloudfront_id" {
  value = module.frontend[0].cloudfront_distribution_id
}
