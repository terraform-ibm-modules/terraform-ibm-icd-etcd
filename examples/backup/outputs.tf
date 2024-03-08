##############################################################################
# Outputs
##############################################################################
output "id" {
  description = "Etcd instance id"
  value       = var.etcd_db_backup_crn == null ? module.etcd_db[0].id : null
}

output "restored_etcd_db_id" {
  description = "Restored Etcd instance id"
  value       = module.restored_etcd_db.id
}

output "restored_etcd_db_version" {
  description = "Restored Etcd instance version"
  value       = module.restored_etcd_db.version
}
