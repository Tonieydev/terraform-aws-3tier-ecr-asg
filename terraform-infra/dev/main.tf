# ---------------------------------------------------------------- Network

module "vpc" {
  source = "../modules/vpc"

  environment        = var.environment
  project            = var.project
  availability_zones = var.availability_zones
  enable_nat_gateway = true
  single_nat_gateway = var.single_nat_gateway

  tags = local.tags
}

module "security_groups" {
  source = "../modules/security-groups"

  environment = var.environment
  project     = var.project
  vpc_id      = module.vpc.vpc_id

  tags = local.tags
}

# ---------------------------------------------------------------- Registry

module "ecr" {
  source = "../modules/ecr"

  environment = var.environment
  project     = var.project

  tags = local.tags
}

# ---------------------------------------------------------------- Database

module "rds" {
  source = "../modules/rds"

  environment       = var.environment
  project           = var.project
  subnet_ids        = module.vpc.database_private_subnet_ids
  security_group_id = module.security_groups.database_instances_sg_id

  db_name        = var.db_name
  db_username    = var.db_username
  instance_class = var.db_instance_class
  multi_az       = var.db_multi_az

  deletion_protection = var.db_protect
  skip_final_snapshot = !var.db_protect

  tags = local.tags
}

# ---------------------------------------------------------------- Identity

module "iam" {
  source = "../modules/iam"

  environment = var.environment
  project     = var.project
  secret_arns = [module.rds.master_secret_arn]

  tags = local.tags
}

# ---------------------------------------------------------------- Load balancers

module "alb" {
  source = "../modules/alb"

  environment       = var.environment
  project           = var.project
  tier              = "frontend"
  internal          = false
  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.public_subnet_ids
  security_group_id = module.security_groups.alb_sg_id
  target_group_port = 3000
  health_check_path = "/"

  tags = local.tags
}

module "internal_alb" {
  source = "../modules/alb"

  environment       = var.environment
  project           = var.project
  tier              = "backend"
  internal          = true
  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.backend_private_subnet_ids
  security_group_id = module.security_groups.internal_alb_sg_id
  target_group_port = 80
  health_check_path = var.backend_health_check_path

  tags = local.tags
}

# ---------------------------------------------------------------- Compute

module "backend_asg" {
  source = "../modules/backend-asg"

  environment = var.environment
  project     = var.project
  region      = var.region

  instance_type = var.backend_instance_type
  min_size      = var.backend_capacity.min
  desired_size  = var.backend_capacity.desired
  max_size      = var.backend_capacity.max

  iam_instance_profile = module.iam.ec2_profile_name
  subnet_ids           = module.vpc.backend_private_subnet_ids
  security_group_ids   = module.security-groups.backend_instances_sg_id
  target_group_arns    = [module.alb.target_group_arn]

  docker_image = "${module.ecr.backend_repository_url}:${var.image_tag}"
  ecr_registry = module.ecr.registry

  db_secret_arn = module.rds.master_secret_arn
  db_host       = module.rds.db_address
  db_port       = module.rds.db_port
  db_name       = var.db_name

  alarm_actions = var.alarm_actions
  tags          = local.tags
}

module "frontend_asg" {
  source = "../modules/frontend-asg"

  environment = var.environment
  project     = var.project
  region      = var.region

  instance_type = var.frontend_instance_type
  min_size      = var.frontend_capacity.min
  desired_size  = var.frontend_capacity.desired
  max_size      = var.frontend_capacity.max

  iam_instance_profile = module.iam.ec2_instance_profile_name
  subnet_ids           = module.vpc.frontend_private_subnet_ids
  security_group_ids   = [module.security_groups.frontend_instances_sg_id]
  target_group_arns    = [module.alb.target_group_arn]

  docker_image         = "${module.ecr.frontend_repository_url}:${var.image_tag}"
  ecr_registry         = module.ecr.registry
  backend_internal_url = "http://${module.alb.alb_dns_name}"

  db_secret_arn = module.rds.master_secret_arn
  db_host       = module.rds.db_address
  db_port       = module.rds.db_port
  db_name       = var.db_name
  alarm_actions = var.alarm_actions
  tags          = local.tags
}