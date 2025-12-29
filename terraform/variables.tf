variable "env" {
  description = "Deployment environment"
  type        = string
  default     = "dev" 
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-3"
}