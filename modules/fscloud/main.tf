module "etcd_db" {
  source                        = "../../"
  resource_group_id             = var.resource_group_id
  instance_name                 = var.instance_name
  region                        = var.region
  skip_iam_authorization_policy = var.skip_iam_authorization_policy
  endpoints                     = "private"
  etcd_version                  = var.etcd_version
  kms_encryption_enabled        = true
  existing_kms_instance_guid    = var.existing_kms_instance_guid
  kms_key_crn                   = var.kms_key_crn
  backup_encryption_key_crn     = null # Need to use default encryption until ICD adds HPCS support for backup encryption
  cbr_rules                     = var.cbr_rules
  tags                          = var.tags
  configuration                 = var.configuration
  members                       = var.members
  memory_mb                     = var.memory_mb
  admin_pass                    = var.admin_pass
  users                         = var.users
  disk_mb                       = var.disk_mb
  cpu_count                     = var.cpu_count
  auto_scaling                  = var.auto_scaling
}
