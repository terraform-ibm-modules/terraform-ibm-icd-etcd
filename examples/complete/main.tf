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

##############################################################################
# Key Protect All Inclusive
##############################################################################

locals {
  data_key_name    = "${var.prefix}-etcd"
  backups_key_name = "${var.prefix}-etcd-backups"
}

module "key_protect_all_inclusive" {
  source                    = "terraform-ibm-modules/kms-all-inclusive/ibm"
  version                   = "4.20.0"
  resource_group_id         = module.resource_group.resource_group_id
  region                    = var.region
  key_protect_instance_name = "${var.prefix}-kp"
  resource_tags             = var.resource_tags
  keys = [
    {
      key_ring_name = "icd"
      keys = [
        {
          key_name     = local.data_key_name
          force_delete = true
        },
        {
          key_name     = local.backups_key_name
          force_delete = true
        }
      ]
    }
  ]
}

##############################################################################
# Etcd Instance
##############################################################################

module "etcd_db" {
  source            = "../../"
  resource_group_id = module.resource_group.resource_group_id
  etcd_version      = var.etcd_version
  name              = "${var.prefix}-etcd"
  region            = var.region
  admin_pass        = var.admin_pass
  users             = var.users
  # Example of how to use different KMS keys for data and backups
  use_ibm_owned_encryption_key = false
  use_same_kms_key_for_backups = false
  kms_key_crn                  = module.key_protect_all_inclusive.keys["icd.${local.data_key_name}"].crn
  backup_encryption_key_crn    = module.key_protect_all_inclusive.keys["icd.${local.backups_key_name}"].crn
  service_credential_names = {
    "etcd_admin" : "Administrator",
    "etcd_operator" : "Operator",
    "etcd_viewer" : "Viewer",
    "etcd_editor" : "Editor",
  }
  access_tags        = var.access_tags
  member_host_flavor = "multitenant"
}
