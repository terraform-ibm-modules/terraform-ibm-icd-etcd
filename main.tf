##############################################################################
# ICD etcd modules
#
# Creates ICD etcd instance
##############################################################################

locals {
  # Validation (approach based on https://github.com/hashicorp/terraform/issues/25609#issuecomment-1057614400)
  # tflint-ignore: terraform_unused_declarations
  validate_kms_values = var.use_ibm_owned_encryption_key && (var.kms_key_crn != null || var.backup_encryption_key_crn != null) ? tobool("When passing values for 'kms_key_crn' or 'backup_encryption_key_crn', you must set 'use_ibm_owned_encryption_key' to false. Otherwise unset them to use default encryption.") : true
  # tflint-ignore: terraform_unused_declarations
  validate_kms_vars = !var.use_ibm_owned_encryption_key && var.kms_key_crn == null ? tobool("When setting 'use_ibm_owned_encryption_key' to false, a value must be passed for 'kms_key_crn'.") : true
  # tflint-ignore: terraform_unused_declarations
  validate_backup_key = !var.use_ibm_owned_encryption_key && var.backup_encryption_key_crn != null && (var.use_default_backup_encryption_key || var.use_same_kms_key_for_backups) ? tobool("When passing a value for 'backup_encryption_key_crn' you cannot set 'use_default_backup_encryption_key' to true or 'use_ibm_owned_encryption_key' to false.") : true
  # tflint-ignore: terraform_unused_declarations
  validate_backup_key_2 = !var.use_ibm_owned_encryption_key && var.backup_encryption_key_crn == null && !var.use_same_kms_key_for_backups ? tobool("When 'use_same_kms_key_for_backups' is set to false, a value needs to be passed for 'backup_encryption_key_crn'.") : true
}

########################################################################################################################
# Locals
########################################################################################################################
locals {
  # If no value passed for 'backup_encryption_key_crn' use the value of 'kms_key_crn' and perform validation of 'kms_key_crn' to check if region is supported by backup encryption key.

  # If 'use_ibm_owned_encryption_key' is true or 'use_default_backup_encryption_key' is true, default to null.
  # If no value is passed for 'backup_encryption_key_crn', then default to use 'kms_key_crn'.
  backup_encryption_key_crn = var.use_ibm_owned_encryption_key || var.use_default_backup_encryption_key ? null : (var.backup_encryption_key_crn != null ? var.backup_encryption_key_crn : var.kms_key_crn)

  # Determine if auto scaling is enabled
  auto_scaling_enabled = var.auto_scaling == null ? [] : [1]

  # Determine if host_flavor is used
  host_flavor_set = var.member_host_flavor != null ? true : false
}

########################################################################################################################
# Parse info from KMS key CRNs
########################################################################################################################

locals {
  parse_kms_key        = !var.use_ibm_owned_encryption_key
  parse_backup_kms_key = !var.use_ibm_owned_encryption_key && !var.use_default_backup_encryption_key
}

module "kms_key_crn_parser" {
  count   = local.parse_kms_key ? 1 : 0
  source  = "terraform-ibm-modules/common-utilities/ibm//modules/crn-parser"
  version = "1.2.0"
  crn     = var.kms_key_crn
}

module "backup_key_crn_parser" {
  count   = local.parse_backup_kms_key ? 1 : 0
  source  = "terraform-ibm-modules/common-utilities/ibm//modules/crn-parser"
  version = "1.2.0"
  crn     = local.backup_encryption_key_crn
}

# Put parsed values into locals
locals {
  kms_service                  = local.parse_kms_key ? module.kms_key_crn_parser[0].service_name : null
  kms_account_id               = local.parse_kms_key ? module.kms_key_crn_parser[0].account_id : null
  kms_key_id                   = local.parse_kms_key ? module.kms_key_crn_parser[0].resource : null
  kms_key_instance_guid        = local.parse_kms_key ? module.kms_key_crn_parser[0].service_instance : null
  backup_kms_service           = local.parse_backup_kms_key ? module.backup_key_crn_parser[0].service_name : null
  backup_kms_account_id        = local.parse_backup_kms_key ? module.backup_key_crn_parser[0].account_id : null
  backup_kms_key_id            = local.parse_backup_kms_key ? module.backup_key_crn_parser[0].resource : null
  backup_kms_key_instance_guid = local.parse_backup_kms_key ? module.backup_key_crn_parser[0].service_instance : null
}

########################################################################################################################
# KMS IAM Authorization Policies
########################################################################################################################

locals {
  # only create auth policy if 'use_ibm_owned_encryption_key' is false, and 'skip_iam_authorization_policy' is false
  create_kms_auth_policy = !var.use_ibm_owned_encryption_key && !var.skip_iam_authorization_policy ? 1 : 0
  # only create backup auth policy if 'use_ibm_owned_encryption_key' is false, 'skip_iam_authorization_policy' is false and 'use_same_kms_key_for_backups' is false
  create_backup_kms_auth_policy = !var.use_ibm_owned_encryption_key && !var.skip_iam_authorization_policy && !var.use_same_kms_key_for_backups ? 1 : 0
}

# Create IAM Access Policy to allow Key protect to access etcd instance
resource "ibm_iam_authorization_policy" "policy" {
  count                    = local.create_kms_auth_policy
  source_service_name      = "databases-for-etcd"
  source_resource_group_id = var.resource_group_id
  roles                    = ["Reader"]
  description              = "Allow all ETCD instances in the resource group ${var.resource_group_id} to read the ${local.kms_service} key ${local.kms_key_id} from the instance GUID ${local.kms_key_instance_guid}"
  resource_attributes {
    name     = "serviceName"
    operator = "stringEquals"
    value    = local.kms_service
  }
  resource_attributes {
    name     = "accountId"
    operator = "stringEquals"
    value    = local.kms_account_id
  }
  resource_attributes {
    name     = "serviceInstance"
    operator = "stringEquals"
    value    = local.kms_key_instance_guid
  }
  resource_attributes {
    name     = "resourceType"
    operator = "stringEquals"
    value    = "key"
  }
  resource_attributes {
    name     = "resource"
    operator = "stringEquals"
    value    = local.kms_key_id
  }
  # Scope of policy now includes the key, so ensure to create new policy before
  # destroying old one to prevent any disruption to every day services.
  lifecycle {
    create_before_destroy = true
  }
}

# workaround for https://github.com/IBM-Cloud/terraform-provider-ibm/issues/4478
resource "time_sleep" "wait_for_authorization_policy" {
  count           = local.create_kms_auth_policy
  depends_on      = [ibm_iam_authorization_policy.policy]
  create_duration = "30s"
}

resource "ibm_iam_authorization_policy" "backup_kms_policy" {
  count                    = local.create_backup_kms_auth_policy
  source_service_name      = "databases-for-etcd"
  source_resource_group_id = var.resource_group_id
  roles                    = ["Reader"]
  description              = "Allow all ETCD instances in the Resource Group ${var.resource_group_id} to read the ${local.backup_kms_service} key ${local.backup_kms_key_id} from the instance GUID ${local.backup_kms_key_instance_guid}"
  resource_attributes {
    name     = "serviceName"
    operator = "stringEquals"
    value    = local.backup_kms_service
  }
  resource_attributes {
    name     = "accountId"
    operator = "stringEquals"
    value    = local.backup_kms_account_id
  }
  resource_attributes {
    name     = "serviceInstance"
    operator = "stringEquals"
    value    = local.backup_kms_key_instance_guid
  }
  resource_attributes {
    name     = "resourceType"
    operator = "stringEquals"
    value    = "key"
  }
  resource_attributes {
    name     = "resource"
    operator = "stringEquals"
    value    = local.backup_kms_key_id
  }
  # Scope of policy now includes the key, so ensure to create new policy before
  # destroying old one to prevent any disruption to every day services.
  lifecycle {
    create_before_destroy = true
  }
}

# workaround for https://github.com/IBM-Cloud/terraform-provider-ibm/issues/4478
resource "time_sleep" "wait_for_backup_kms_authorization_policy" {
  count           = local.create_backup_kms_auth_policy
  depends_on      = [ibm_iam_authorization_policy.backup_kms_policy]
  create_duration = "30s"
}

########################################################################################################################
# ETCD instance
########################################################################################################################

# Create etcd database
resource "ibm_database" "etcd_db" {
  depends_on                = [time_sleep.wait_for_authorization_policy, time_sleep.wait_for_backup_kms_authorization_policy]
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

  # Workaround for https://github.ibm.com/GoldenEye/issues/issues/11359
  # means that no `group` block is added when restoring from backup

  ## This for_each block is NOT a loop to attach to multiple group blocks.
  ## This is used to conditionally add one, OR, the other group block depending on var.local.host_flavor_set
  ## This block is for if host_flavor IS set to specific pre-defined host sizes and not set to "multitenant"
  dynamic "group" {
    for_each = local.host_flavor_set && var.member_host_flavor != "multitenant" && var.backup_crn == null ? [1] : []
    content {
      group_id = "member" # Only member type is allowed for IBM Cloud Databases
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
    for_each = local.host_flavor_set && var.member_host_flavor == "multitenant" && var.backup_crn == null ? [1] : []
    content {
      group_id = "member" # Only member type is allowed for IBM Cloud Databases
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
    for_each = !local.host_flavor_set && var.backup_crn == null ? [1] : []
    content {
      group_id = "member" # Only member type is allowed for IBM Cloud Databases
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
  version          = "1.32.0"
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
  #  There is only 1 operation type for etcd so it is not exposed as a configuration
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
