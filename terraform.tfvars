################################################################################
# General Settings
################################################################################
name        = "rdsmssqlwithad"
region      = "us-east-1"

general-tags = {
  Owner       = "user"
  Environment = "dev"
}

################################################################################
# AWS Directory Service (Acitve Directory)
################################################################################
ad-name     = "corp.company-name.com"
ad-password = "1234@AdPassword"
ad-edition  = "Standard"

################################################################################
# RDS Module
################################################################################
rds-engine               = "sqlserver-ex"
rds-engine-version       = "15.00.4153.1.v1"
rds-family               = "sqlserver-ex-15.0" # DB parameter group
rds-major-engine-version = "15.00"             # DB option group
rds-instance-class       = "db.t3.large"

rds-allocated-storage     = 20
rds-max-allocated-storage = 100

rds-username = "username"
rds-port     = 1433

rds-maintenance-window = "Mon:00:00-Mon:03:00"
rds-backup-window      = "03:00-06:00"
rds-timezone           = "Eastern Standard Time"
