output "ec2_public_ip" {
  description = "IP publico da instancia EC2"
  value       = module.ec2.public_ip
}

output "ec2_public_dns" {
  description = "DNS publico da instancia EC2"
  value       = module.ec2.public_dns
}

output "rds_endpoint" {
  description = "Endpoint de conexao do RDS"
  value       = module.rds.db_endpoint
}

output "api_url" {
  description = "URL base da API"
  value       = "http://${module.ec2.public_ip}:3000"
}
