
module "vpc" {
  source = "./vpc" 

  env      = var.env 
  
  vpc_cidr = "10.0.0.0/16"
  azs      = ["eu-west-3a", "eu-west-3b"]
  
  public_subnets_cidr       = ["10.0.1.0/24", "10.0.2.0/24"]
  private_app_subnets_cidr  = ["10.0.3.0/24", "10.0.4.0/24"]
  private_data_subnets_cidr = ["10.0.5.0/24", "10.0.6.0/24"]
}

module "rds" {
  source = "./rds"

  env                = var.env
  vpc_id             = module.vpc.vpc_id
  
  private_subnet_ids = module.vpc.private_data_subnet_ids
  
  db_instance_class  = "db.t3.micro"
}

resource "aws_s3_bucket" "app_assets" {
  bucket = "pelazas1-inventory-assets-${var.env}" # Unique name

  force_destroy = true 
}

# Public access block (Best practices)
resource "aws_s3_bucket_public_access_block" "app_assets" {
  bucket = aws_s3_bucket.app_assets.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}