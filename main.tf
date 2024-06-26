##############################################################################
# ICD etcd modules
#
# Creates ICD etcd instance
##############################################################################

locals {
  # Validation (approach based on https://github.com/hashicorp/terraform/issues/25609#issuecomment-1057614400)
  # tflint-ignore: terraform_unused_declarations
  validate_kms_values = !var.kms_encryption_enabled && (var.kms_key_crn != null || var.backup_encryption_key_crn != null) ? tobool("When passing values for var.backup_encryption_key_crn or var.kms_key_crn, you must set var.kms_encryption_enabled to true. Otherwise unset them to use default encryption") : true
  # tflint-ignore: terraform_unused_declarations
  validate_kms_vars = var.kms_encryption_enabled && var.kms_key_crn == null && var.backup_encryption_key_crn == null ? tobool("When setting var.kms_encryption_enabled to true, a value must be passed for var.kms_key_crn and/or var.backup_encryption_key_crn") : true
  # tflint-ignore: terraform_unused_declarations
  validate_auth_policy = var.kms_encryption_enabled && var.skip_iam_authorization_policy == false && var.existing_kms_instance_guid == null ? tobool("When var.skip_iam_authorization_policy is set to false, and var.kms_encryption_enabled to true, a value must be passed for var.existing_kms_instance_guid in order to create the auth policy.") : true
  # tflint-ignore: terraform_unused_declarations
  validate_backup_key = var.backup_encryption_key_crn != null && var.use_default_backup_encryption_key == true ? tobool("When passing a value for 'backup_encryption_key_crn' you cannot set 'use_default_backup_encryption_key' to 'true'") : true

  # If no value passed for 'backup_encryption_key_crn' use the value of 'kms_key_crn'. If this is a HPCS key (which is not currently supported for backup encryption), default to 'null' meaning encryption is done using randomly generated keys
  # More info https://cloud.ibm.com/docs/cloud-databases?topic=cloud-databases-hpcs
  backup_encryption_key_crn = var.use_default_backup_encryption_key == true ? null : (var.backup_encryption_key_crn != null ? var.backup_encryption_key_crn : (can(regex(".*kms.*", var.kms_key_crn)) ? var.kms_key_crn : null))

  # Determine if auto scaling is enabled
  auto_scaling_enabled = var.auto_scaling == null ? [] : [1]

  # Determine if host_flavor is used
  host_flavor_set = var.member_host_flavor != null ? true : false

  # Determine what KMS service is being used for database encryption
  kms_service = var.kms_key_crn != null ? (
    can(regex(".*kms.*", var.kms_key_crn)) ? "kms" : (
      can(regex(".*hs-crypto.*", var.kms_key_crn)) ? "hs-crypto" : null
    )
  ) : null
}

# Create IAM Access Policy to allow Key protect to access etcd instance
resource "ibm_iam_authorization_policy" "policy" {
  count                       = var.kms_encryption_enabled == false || var.skip_iam_authorization_policy ? 0 : 1
  source_service_name         = "databases-for-etcd"
  source_resource_group_id    = var.resource_group_id
  target_service_name         = local.kms_service
  target_resource_instance_id = var.existing_kms_instance_guid
  roles                       = ["Reader"]
}

# workaround for https://github.com/IBM-Cloud/terraform-provider-ibm/issues/4478
resource "time_sleep" "wait_for_authorization_policy" {
  depends_on = [ibm_iam_authorization_policy.policy]

  create_duration = "30s"
}


# Create etcd database
resource "ibm_database" "etcd_db" {
  depends_on                = [time_sleep.wait_for_authorization_policy]
  resource_group_id         = var.resource_group_id
  name                      = var.name
  service                   = "databases-for-etcd"
  location                  = var.region
  plan                      = "standard" # Only standard plan is available for etcd
  backup_id                 = var.backup_crn
  version                   = var.etcd_version
  tags                      = var.tags
  adminpassword             = var.admin_pass
  service_endpoints         = var.service_endpoints
  key_protect_key           = var.kms_key_crn
  backup_encryption_key_crn = local.backup_encryption_key_crn

  dynamic "users" {
    for_each = nonsensitive(var.users != null ? var.users : [])
    content {
      name     = users.value.name
      password = users.value.password
      type     = users.value.type
      role     = (users.value.role != "" ? users.value.role : null)
    }
  }

  ## This for_each block is NOT a loop to attach to multiple group blocks.
  ## This is used to conditionally add one, OR, the other group block depending on var.local.host_flavor_set
  ## This block is for if host_flavor IS set to specific pre-defined host sizes and not set to "multitenant"
  dynamic "group" {
    for_each = local.host_flavor_set && var.member_host_flavor != "multitenant" ? [1] : []
    content {
      group_id = "member" # Only member type is allowed for postgresql
      host_flavor {
        id = var.member_host_flavor
      }
      disk {
        allocation_mb = var.member_disk_mb
      }
      members {
        allocation_count = var.members
      }
    }
  }

  ## This block is for if host_flavor IS set to "multitenant"
  dynamic "group" {
    for_each = local.host_flavor_set && var.member_host_flavor == "multitenant" ? [1] : []
    content {
      group_id = "member" # Only member type is allowed for postgresql
      host_flavor {
        id = var.member_host_flavor
      }
      disk {
        allocation_mb = var.member_disk_mb
      }
      memory {
        allocation_mb = var.member_memory_mb
      }
      cpu {
        allocation_count = var.member_cpu_count
      }
      members {
        allocation_count = var.members
      }
    }
  }

  ## This block is for if host_flavor IS NOT set
  dynamic "group" {
    for_each = local.host_flavor_set ? [] : [1]
    content {
      group_id = "member" # Only member type is allowed for postgresql
      memory {
        allocation_mb = var.member_memory_mb
      }
      disk {
        allocation_mb = var.member_disk_mb
      }
      cpu {
        allocation_count = var.member_cpu_count
      }
      members {
        allocation_count = var.members
      }
    }
  }

  dynamic "auto_scaling" {
    for_each = local.auto_scaling_enabled
    content {
      disk {
        capacity_enabled             = var.auto_scaling.disk.capacity_enabled
        free_space_less_than_percent = var.auto_scaling.disk.free_space_less_than_percent
        io_above_percent             = var.auto_scaling.disk.io_above_percent
        io_enabled                   = var.auto_scaling.disk.io_enabled
        io_over_period               = var.auto_scaling.disk.io_over_period
        rate_increase_percent        = var.auto_scaling.disk.rate_increase_percent
        rate_limit_mb_per_member     = var.auto_scaling.disk.rate_limit_mb_per_member
        rate_period_seconds          = var.auto_scaling.disk.rate_period_seconds
        rate_units                   = var.auto_scaling.disk.rate_units
      }
      memory {
        io_above_percent         = var.auto_scaling.memory.io_above_percent
        io_enabled               = var.auto_scaling.memory.io_enabled
        io_over_period           = var.auto_scaling.memory.io_over_period
        rate_increase_percent    = var.auto_scaling.memory.rate_increase_percent
        rate_limit_mb_per_member = var.auto_scaling.memory.rate_limit_mb_per_member
        rate_period_seconds      = var.auto_scaling.memory.rate_period_seconds
        rate_units               = var.auto_scaling.memory.rate_units
      }
    }
  }
  lifecycle {
    ignore_changes = [
      # Ignore changes to these because a change will destroy and recreate the instance
      version,
      key_protect_key,
      backup_encryption_key_crn,
    ]
  }
  timeouts {
    create = "120m" # Extending provisioning time to 120 minutes
  }
}

resource "ibm_resource_tag" "etcd_tag" {
  count       = length(var.access_tags) == 0 ? 0 : 1
  resource_id = ibm_database.etcd_db.resource_crn
  tags        = var.access_tags
  tag_type    = "access"
}

##############################################################################
# Context Based Restrictions
##############################################################################

module "cbr_rule" {
  count            = length(var.cbr_rules) > 0 ? length(var.cbr_rules) : 0
  source           = "terraform-ibm-modules/cbr/ibm//modules/cbr-rule-module"
  version          = "1.22.2"
  rule_description = var.cbr_rules[count.index].description
  enforcement_mode = var.cbr_rules[count.index].enforcement_mode
  rule_contexts    = var.cbr_rules[count.index].rule_contexts
  resources = [{
    attributes = [
      {
        name     = "accountId"
        value    = var.cbr_rules[count.index].account_id
        operator = "stringEquals"
      },
      {
        name     = "serviceInstance"
        value    = ibm_database.etcd_db.guid
        operator = "stringEquals"
      },
      {
        name     = "serviceName"
        value    = "databases-for-etcd"
        operator = "stringEquals"
      }
    ]
  }]
  #  There is only 1 operation type for Elasticsearch so it is not exposed as a configuration
  operations = [{
    api_types = [
      {
        api_type_id = "crn:v1:bluemix:public:context-based-restrictions::::api-type:data-plane"
      }
    ]
  }]
}

##############################################################################
# Service Credentials
##############################################################################

resource "ibm_resource_key" "service_credentials" {
  for_each             = var.service_credential_names
  name                 = each.key
  role                 = each.value
  resource_instance_id = ibm_database.etcd_db.id
}

locals {
  # used for output only
  service_credentials_json = length(var.service_credential_names) > 0 ? {
    for service_credential in ibm_resource_key.service_credentials :
    service_credential["name"] => service_credential["credentials_json"]
  } : null

  service_credentials_object = length(var.service_credential_names) > 0 ? {
    hostname    = ibm_resource_key.service_credentials[keys(var.service_credential_names)[0]].credentials["connection.grpc.hosts.0.hostname"]
    port        = ibm_resource_key.service_credentials[keys(var.service_credential_names)[0]].credentials["connection.grpc.hosts.0.port"]
    certificate = ibm_resource_key.service_credentials[keys(var.service_credential_names)[0]].credentials["connection.grpc.certificate.certificate_base64"]
    credentials = {
      for service_credential in ibm_resource_key.service_credentials :
      service_credential["name"] => {
        username = service_credential.credentials["connection.grpc.authentication.username"]
        password = service_credential.credentials["connection.grpc.authentication.password"]
      }
    }
  } : null
}

data "ibm_database_connection" "database_connection" {
  endpoint_type = var.service_endpoints == "public-and-private" ? "public" : var.service_endpoints
  deployment_id = ibm_database.etcd_db.id
  user_id       = ibm_database.etcd_db.adminuser
  user_type     = "database"
}
