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

output "hostname" {
  description = "Etcd instance hostname"
  value       = module.etcd_db.hostname
}

output "port" {
  description = "Etcd instance port"
  value       = module.etcd_db.port
}
