# ── VPC ───────────────────────────────────────────────────────────────────────
module "vpc" {
  source  = "./modules/vpc"
  project = var.project
}

# ── Security Groups ───────────────────────────────────────────────────────────
module "security_group" {
  source  = "./modules/security-group"
  project = var.project
  vpc_id  = module.vpc.vpc_id
}

# ── RDS (criado antes da EC2 para obter o endpoint) ───────────────────────────
module "rds" {
  source             = "./modules/rds"
  project            = var.project
  private_subnet_ids = module.vpc.private_subnet_ids
  rds_sg_id          = module.security_group.rds_sg_id
  db_user            = var.db_user
  db_password        = var.db_password
  db_name            = var.db_name
}

# ── EC2 ───────────────────────────────────────────────────────────────────────
module "ec2" {
  source           = "./modules/ec2"
  project          = var.project
  public_subnet_id = module.vpc.public_subnet_ids[0]
  ec2_sg_id        = module.security_group.ec2_sg_id
  key_name         = var.key_name
  app_repo_url     = var.app_repo_url
  db_host          = module.rds.db_host
  db_user          = var.db_user
  db_password      = var.db_password
  db_name          = var.db_name
}
