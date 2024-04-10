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

output "adminuser" {
  description = "Database admin user name"
  value       = module.etcd_db.adminuser
}

output "hostname" {
  description = "Database connection hostname"
  value       = module.etcd_db.hostname
}

output "port" {
  description = "Database connection port"
  value       = module.etcd_db.port
}

output "certificate_base64" {
  description = "Database connection certificate"
  value       = module.etcd_db.certificate_base64
  sensitive   = true
}
