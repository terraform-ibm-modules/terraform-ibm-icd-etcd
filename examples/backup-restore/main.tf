##############################################################################
# Resource Group
##############################################################################

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.1.6"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

data "ibm_database_backups" "backup_database" {
  deployment_id = var.existing_database_crn
}

# New etcd db instance pointing to the backup instance
module "restored_icd_etcd" {
  source             = "../.."
  resource_group_id  = module.resource_group.resource_group_id
  name               = "${var.prefix}-etcd-restored"
  region             = var.region
  etcd_version       = var.etcd_version
  access_tags        = var.access_tags
  tags               = var.resource_tags
  member_host_flavor = "multitenant"
  backup_crn         = data.ibm_database_backups.backup_database.backups[0].backup_id
}
