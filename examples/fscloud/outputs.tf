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
  description = "Database hostname. Only contains value when var.service_credential_names or var.users are set."
  value       = module.etcd_db.hostname
}

output "port" {
  description = "Database port. Only contains value when var.service_credential_names or var.users are set."
  value       = module.etcd_db.port
}
