provider "aws" {
  region = local.region
}

################################################################################
# General Settings
################################################################################

locals {
  name   = var.name
  region = var.region
  tags   = var.general-tags
}

################################################################################
# AWS Directory Service (Acitve Directory)
################################################################################

resource "aws_directory_service_directory" "ad" {
  name     = var.ad-name
  password = var.ad-password
  edition  = var.ad-edition
  type     = "MicrosoftAD"

  vpc_settings {
    vpc_id = var.vpc-id #module.vpc.vpc_id
    # Only 2 subnets, must be in different AZs
    subnet_ids = var.ad-subnet-ids #slice(tolist(module.vpc.database_subnets), 0, 2)
  }

  tags = local.tags
}

################################################################################
# RDS Module 
################################################################################

module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "4.1.3"

  identifier = local.name

  engine               = var.rds-engine
  engine_version       = var.rds-engine-version
  family               = var.rds-family               # DB parameter group
  major_engine_version = var.rds-major-engine-version # DB option group
  instance_class       = var.rds-instance-class

  allocated_storage     = var.rds-allocated-storage
  max_allocated_storage = var.rds-max-allocated-storage

  username = var.rds-username
  port     = var.rds-port

  domain               = aws_directory_service_directory.ad.id
  domain_iam_role_name = var.ad-iam-role #aws_iam_role.rds_ad_auth.name

  multi_az               = false
  subnet_ids             = var.db-subnet-ids         #module.vpc.database_subnets
  vpc_security_group_ids = var.db-security-group-ids #[module.security_group.security_group_id]

  maintenance_window              = var.rds-maintenance-window
  backup_window                   = var.rds-backup-window
  enabled_cloudwatch_logs_exports = ["error"]
  create_cloudwatch_log_group     = true

  backup_retention_period = 0
  skip_final_snapshot     = true
  deletion_protection     = false

  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  create_monitoring_role                = true
  monitoring_interval                   = 60

  storage_encrypted = false

  options                   = []
  create_db_parameter_group = false
  license_model             = "license-included"
  timezone                  = var.rds-timezone
  character_set_name        = "Latin1_General_CI_AS"

  tags = local.tags
}

module "db_disabled" {
  source  = "terraform-aws-modules/rds/aws"
  version = "4.1.3"

  identifier = "${local.name}-disabled"

  create_db_instance        = true #false
  create_db_parameter_group = false
  create_db_option_group    = false
}
