variable "project" {
  type        = string
  default     = "prova-devops"
  description = "Prefixo de nomenclatura de todos os recursos"
}

variable "key_name" {
  type        = string
  description = "Nome do Key Pair existente no AWS Academy para acesso SSH"
}

variable "app_repo_url" {
  type        = string
  description = "URL do repositorio Git com o codigo da aplicacao"
}

variable "db_user" {
  type        = string
  default     = "postgres"
  description = "Usuario do banco de dados PostgreSQL"
}

variable "db_password" {
  type        = string
  sensitive   = true
  description = "Senha do banco de dados PostgreSQL"
}

variable "db_name" {
  type        = string
  default     = "reservas"
  description = "Nome do banco de dados PostgreSQL"
}
