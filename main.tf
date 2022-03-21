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
# Supporting Resources
################################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.0"

  name = local.name
  cidr = "10.99.0.0/18"

  azs              = ["${local.region}a", "${local.region}b", "${local.region}c"]
  public_subnets   = ["10.99.0.0/24", "10.99.1.0/24", "10.99.2.0/24"]
  private_subnets  = ["10.99.3.0/24", "10.99.4.0/24", "10.99.5.0/24"]
  database_subnets = ["10.99.7.0/24", "10.99.8.0/24", "10.99.9.0/24"]

  create_database_subnet_group = true

  tags = local.tags
}

module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.0"

  name        = local.name
  description = "SqlServer security group"
  vpc_id      = module.vpc.vpc_id

  # ingress
  ingress_with_cidr_blocks = [
    {
      from_port   = 1433
      to_port     = 1433
      protocol    = "tcp"
      description = "SqlServer access from within VPC"
      cidr_blocks = module.vpc.vpc_cidr_block
    },
  ]

  tags = local.tags
}

################################################################################
# IAM Role for Windows Authentication
################################################################################

data "aws_iam_policy_document" "rds_assume_role" {
  statement {
    sid = "AssumeRole"

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["rds.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "rds_ad_auth" {
  name                  = "rds-ad-auth"
  description           = "Role used by RDS for Active Directory authentication and authorization"
  force_detach_policies = true
  assume_role_policy    = data.aws_iam_policy_document.rds_assume_role.json

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "rds_directory_services" {
  role       = aws_iam_role.rds_ad_auth.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSDirectoryServiceAccess"
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
    vpc_id = module.vpc.vpc_id
    # Only 2 subnets, must be in different AZs
    subnet_ids = slice(tolist(module.vpc.database_subnets), 0, 2)
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
  domain_iam_role_name = aws_iam_role.rds_ad_auth.name

  multi_az               = false
  subnet_ids             = module.vpc.database_subnets
  vpc_security_group_ids = [module.security_group.security_group_id]

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

  create_db_instance        = false
  create_db_parameter_group = false
  create_db_option_group    = false
}
