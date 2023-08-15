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

output "hostname" {
  description = "Database hostname. Only contains value when var.service_credential_names or var.users are set."
  value       = module.etcd_db.hostname
}

output "port" {
  description = "Database port. Only contains value when var.service_credential_names or var.users are set."
  value       = module.etcd_db.port
}
