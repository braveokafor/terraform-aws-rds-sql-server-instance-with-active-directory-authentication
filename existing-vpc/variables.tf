################################################################################
# General Settings
################################################################################
variable "name" {}
variable "region" {}
variable "general-tags" {}

################################################################################
# AWS Directory Service (Acitve Directory)
################################################################################
variable "ad-name" {}
variable "ad-password" {}
variable "ad-edition" {}

################################################################################
# RDS Module
################################################################################
variable "rds-engine" {}
variable "rds-engine-version" {}
variable "rds-family" {}
variable "rds-major-engine-version" {}
variable "rds-instance-class" {}
variable "rds-allocated-storage" {}
variable "rds-max-allocated-storage" {}
variable "rds-username" {}
variable "rds-port" {}
variable "rds-maintenance-window" {}
variable "rds-backup-window" {}
variable "rds-timezone" {}

################################################################################
# Added Variables
################################################################################
variable "vpc-id" {}
variable "ad-subnet-ids" {}

variable "db-subnet-ids" {}
variable "db-security-group-ids" {}
variable "ad-iam-role" {}
