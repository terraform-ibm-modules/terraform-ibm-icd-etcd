##############################################################################
# Outputs
##############################################################################

output "id" {
  description = "etcd instance id"
  value       = module.etcd_db.id
}

output "guid" {
  description = "etcd instance guid"
  value       = module.etcd_db.guid
}
