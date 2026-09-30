variable "project" {
  type = string
}

variable "public_subnet_id" {
  type = string
}

variable "ec2_sg_id" {
  type = string
}

variable "key_name" {
  type        = string
  description = "Nome do Key Pair existente na conta AWS"
}

variable "app_repo_url" {
  type        = string
  description = "URL do repositorio Git da aplicacao"
}

variable "db_host" {
  type = string
}

variable "db_user" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "db_name" {
  type = string
}
