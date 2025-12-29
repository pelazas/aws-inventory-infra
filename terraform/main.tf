provider "aws" {
  region = "eu-west-3" # O tu región preferida
}

# 1. VPC
module "vpc" {
  source = "./vpc" 

  env      = var.env 
  vpc_cidr = "10.0.0.0/16"
  azs      = ["eu-west-3a", "eu-west-3b"]
  
  public_subnets_cidr       = ["10.0.1.0/24", "10.0.2.0/24"]
  private_app_subnets_cidr  = ["10.0.3.0/24", "10.0.4.0/24"]
  private_data_subnets_cidr = ["10.0.5.0/24", "10.0.6.0/24"]
}

# 2. SECURITY
module "security" {
  source = "./security"
  vpc_id = module.vpc.vpc_id
}

# 3. ECR
module "ecr" {
  source    = "./ecr"
  repo_name = "product-inventory-api"
}

# 4. RDS
module "rds" {
  source = "./rds"

  env                = var.env
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_data_subnet_ids
  db_instance_class  = "db.t3.micro"
  
  # Now we pass the RDS SG from the security module
  security_group_ids = [module.security.rds_sg_id]
}

# 5. ALB
module "alb" {
  source = "./alb"

  vpc_id          = module.vpc.vpc_id
  public_subnets  = module.vpc.public_subnet_ids
  security_groups = [module.security.alb_sg_id]
}

# 6. ECS FARGATE
module "ecs" {
  source = "./ecs"

  private_subnets      = module.vpc.private_app_subnet_ids 
  security_groups      = [module.security.ecs_sg_id]
  app_image            = module.ecr.repository_url
  alb_target_group_arn = module.alb.target_group_arn
  
  app_count = 1
}

# 7. STORAGE (S3)
resource "aws_s3_bucket" "app_assets" {
  bucket        = "pelazas1-inventory-assets-${var.env}" 
  force_destroy = true 
}

resource "aws_s3_bucket_public_access_block" "app_assets" {
  bucket = aws_s3_bucket.app_assets.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

# FINAL OUTPUT
output "app_url" {
  value = "http://${module.alb.dns_name}"
}