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

output "hostname" {
  description = "Etcd instance hostname"
  value       = module.etcd_db.hostname
}

output "port" {
  description = "Etcd instance port"
  value       = module.etcd_db.port
}
