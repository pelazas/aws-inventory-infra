variable "env" {
  description = "El entorno de despliegue (dev, prod)"
  type        = string
  default     = "dev" 
}

variable "region" {
  description = "Región de AWS"
  type        = string
  default     = "eu-west-3"
}