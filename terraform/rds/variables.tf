variable "env" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "IDs de las subnets privadas de datos"
}

variable "db_instance_class" {
  type        = string
  description = "Tipo de instancia RDS (ej. db.t3.micro)"
}

variable "security_group_ids" {
  description = "Lista de Security Group IDs para asignar a la RDS"
  type        = list(string)
}