
module "vpc" {
  source = "./vpc"

  env      = "dev" 
  vpc_cidr = "10.0.0.0/16"
  
  azs      = ["eu-west-3a", "eu-west-3b"] 
  
  public_subnets_cidr       = ["10.0.1.0/24", "10.0.2.0/24"]
  private_app_subnets_cidr  = ["10.0.3.0/24", "10.0.4.0/24"]
  private_data_subnets_cidr = ["10.0.5.0/24", "10.0.6.0/24"]
}