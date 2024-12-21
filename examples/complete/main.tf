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

module "key_protect_all_inclusive" {
  source                    = "terraform-ibm-modules/kms-all-inclusive/ibm"
  version                   = "4.19.1"
  resource_group_id         = module.resource_group.resource_group_id
  region                    = var.region
  key_protect_instance_name = "${var.prefix}-kp"
  resource_tags             = var.resource_tags
  keys = [
    {
      key_ring_name = "icd-etcd"
      keys = [
        {
          key_name     = "${var.prefix}-etcd"
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
  source                     = "../../"
  resource_group_id          = module.resource_group.resource_group_id
  name                       = "${var.prefix}-etcd"
  region                     = var.region
  etcd_version               = var.etcd_version
  kms_encryption_enabled     = true
  admin_pass                 = var.admin_pass
  users                      = var.users
  kms_key_crn                = module.key_protect_all_inclusive.keys["icd-etcd.${var.prefix}-etcd"].crn
  existing_kms_instance_guid = module.key_protect_all_inclusive.kms_guid
  tags                       = var.resource_tags
  access_tags                = var.access_tags
  service_credential_names   = var.service_credential_names
  member_host_flavor         = "multitenant"
}
