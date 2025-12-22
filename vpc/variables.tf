variable "env" {
  description = "dev/prod"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR for the VPC"
  type        = string
}

variable "azs" {
  description = "List of Availability Zones"
  type        = list(string)
}

variable "public_subnets_cidr" {
  description = "CIDR for public subnets"
  type        = list(string)
}

variable "private_app_subnets_cidr" {
  description = "CIDR for private app subnets"
  type        = list(string)
}

variable "private_data_subnets_cidr" {
  description = "CIDR for private data subnets"
  type        = list(string)
}