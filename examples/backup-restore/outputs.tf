##############################################################################
# Outputs
##############################################################################

output "restored_etcd_db_id" {
  description = "Restored etcd db instance id"
  value       = module.restored_etcd_db.id
}

output "restored_etcd_db_version" {
  description = "Restored etcd instance version"
  value       = module.restored_etcd_db.version
}
