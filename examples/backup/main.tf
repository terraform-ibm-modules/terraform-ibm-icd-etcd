##############################################################################
# Resource Group
##############################################################################

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.1.4"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

module "etcd_db" {
  count             = var.etcd_db_backup_crn != null ? 0 : 1
  source            = "../.."
  resource_group_id = module.resource_group.resource_group_id
  name              = "${var.prefix}-etcd"
  etcd_version      = var.etcd_version
  region            = var.region
  tags              = var.resource_tags
  access_tags       = var.access_tags
}

data "ibm_database_backups" "backup_database" {
  count         = var.etcd_db_backup_crn != null ? 0 : 1
  deployment_id = module.etcd_db[0].id
}

# New etcd instance pointing to the backup instance
module "restored_etcd_db" {
  source            = "../.."
  resource_group_id = module.resource_group.resource_group_id
  name              = "${var.prefix}-etcd-restored"
  etcd_version      = var.etcd_version
  region            = var.region
  tags              = var.resource_tags
  access_tags       = var.access_tags
  backup_crn        = var.etcd_db_backup_crn == null ? data.ibm_database_backups.backup_database[0].backups[0].backup_id : var.etcd_db_backup_crn
}
