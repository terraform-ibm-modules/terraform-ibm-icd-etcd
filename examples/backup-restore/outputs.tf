##############################################################################
# Outputs
##############################################################################

output "restored_icd_etcd_id" {
  description = "Restored etcd db instance id"
  value       = module.restored_icd_etcd.id
}

output "restored_icd_etcd_version" {
  description = "Restored etcd instance version"
  value       = module.restored_icd_etcd.version
}
