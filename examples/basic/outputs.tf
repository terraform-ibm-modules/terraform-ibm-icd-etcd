##############################################################################
# Outputs
##############################################################################
output "id" {
  description = "Etcd instance id"
  value       = module.etcd_db.id
}

output "version" {
  description = "Etcd instance version"
  value       = module.etcd_db.version
}
