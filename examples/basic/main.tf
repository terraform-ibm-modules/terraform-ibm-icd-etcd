##############################################################################
# Resource Group
##############################################################################

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.2.1"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

##############################################################################
# ICD etcd database
##############################################################################

module "database" {
  source             = "../.."
  resource_group_id  = module.resource_group.resource_group_id
  name               = "${var.prefix}-data-store"
  region             = var.region
  access_tags        = var.access_tags
  service_endpoints  = var.service_endpoints
  member_host_flavor = var.member_host_flavor
  tags               = var.resource_tags
  etcd_version       = var.etcd_version
  service_credential_names = {
    "etcd_admin" : "Administrator",
    "etcd_operator" : "Operator",
    "etcd_viewer" : "Viewer",
    "etcd_editor" : "Editor",
  }
}
