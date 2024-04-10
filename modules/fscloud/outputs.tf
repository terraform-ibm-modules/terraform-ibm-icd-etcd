##############################################################################
# Outputs
##############################################################################

output "id" {
  description = "etcd db instance id"
  value       = module.etcd_db.id
}

output "guid" {
  description = "etcd db instance guid"
  value       = module.etcd_db.guid
}

output "version" {
  description = "etcd db instance version"
  value       = module.etcd_db.version
}

output "crn" {
  description = "etcd db instance crn"
  value       = module.etcd_db.crn
}

output "cbr_rule_ids" {
  description = "CBR rule ids created to restrict etcd db"
  value       = module.etcd_db.cbr_rule_ids
}

output "service_credentials_json" {
  description = "Service credentials json map"
  value       = module.etcd_db.service_credentials_json
  sensitive   = true
}

output "service_credentials_object" {
  description = "Service credentials object"
  value       = module.etcd_db.service_credentials_object
  sensitive   = true
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
