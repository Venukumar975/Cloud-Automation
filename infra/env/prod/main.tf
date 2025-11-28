module "vpc" {
  source = "../../modules/vpc"
  project_name       = var.project_name
  region             = var.region
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets
  nat_gateway        = var.nat_gateway
}

module "ssm_iam" {
  source       = "../../modules/ssm_iam"
  project_name = var.project_name
}


module "compute" {
  source           = "../../modules/compute"
  project_name     = var.project_name
  vpc_id           = module.vpc.vpc_id
  private_subnets  = module.vpc.private_subnet_ids
  public_subnets   = module.vpc.public_subnet_ids
  app_port         = var.app_port
  instance_type    = var.instance_type
  min_size         = var.min_instances
  max_size         = var.max_instances
  desired_capacity = var.desired_instances
  instance_profile_name = module.ssm_iam.instance_profile_name
  service_name = "backend"
  container_port = var.app_port
  region = var.region
}


module "database" {
  count = var.enable_rds ? 1 : 0
  source = "../../modules/database"

  project_name        = var.project_name
  vpc_id              = module.vpc.vpc_id
  private_subnets     = module.vpc.private_subnet_ids

  app_sg_id = module.compute.app_sg_id

  engine              = var.db_engine
  engine_version      = var.db_version
  instance_class      = var.db_instance_class
  storage_gb          = var.db_storage
  multi_az            = var.db_multi_az
  publicly_accessible = var.db_public
}

module "cache" {
  count = var.enable_redis ? 1 : 0
  source = "../../modules/cache"

  project_name    = var.project_name
  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnet_ids
  app_sg_id = module.compute.app_sg_id
  node_type       = var.cache_node_type
  num_cache_nodes = var.cache_num_nodes
}

module "frontend" {
  count           = var.frontend_enabled ? 1 : 0
  source          = "../../modules/frontend"
  project_name    = var.project_name
  enable_frontend = var.frontend_enabled
}


module "monitoring" {
  source = "../../modules/monitoring"

  project_name              = var.project_name
  asg_name                  = module.compute.asg_name
  asg_policy_scale_out_arn  = module.compute.scale_out_policy_arn
  asg_policy_scale_in_arn   = module.compute.scale_in_policy_arn
}

module "ecr" {
  source       = "../../modules/ecr"
  project_name = var.project_name
  environment  = "prod"
  services     = ["backend"] # or ["backend", "auth", "teacher-api"]
}


module "ci_cd_iam" {
  source       = "../../modules/ci_cd_iam"
  project_name = var.project_name

  owner = var.owner
  repo  = var.repo
}


resource "local_file" "deployment_config" {
  filename = "${path.root}/deployment-config.yaml"

  content = yamlencode({
    backend = {
      "backend" = {
        image_repo          = module.ecr.ecr_repo_urls["backend"]
        launch_template_id  = module.compute.launch_template_id
        asg_name            = module.compute.asg_name
        region              = var.region
        port                = var.app_port
        ssm_param_name      = "/${var.project_name}/compute/backend/image_tag"
      }
    }

    frontend = var.frontend_enabled ? {
      "frontend-app" = {
        bucket        = module.frontend[0].bucket_name
        region        = var.region
        cloudfront_id = module.frontend[0].cloudfront_distribution_id
      }
    } : {}
  })
}
