terraform {
  backend "s3" {
    bucket         = "pelazas1-tf-state-inventory"
    
    key            = "global/s3/terraform.tfstate"
    region         = "eu-west-3"
    
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}