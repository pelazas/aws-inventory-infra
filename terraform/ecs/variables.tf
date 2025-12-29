variable "private_subnets" { type = list(string) }
variable "security_groups" { type = list(string) }
variable "app_image" { type = string }
variable "alb_target_group_arn" { type = string }
variable "cpu" { default = 256 }
variable "memory" { default = 512 }
variable "app_count" { default = 1 }