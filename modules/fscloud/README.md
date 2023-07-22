# Profile for IBM Cloud Framework for Financial Services

This code is a version of the [parent root module](../../) that includes a default configuration that complies with the relevant controls from the [IBM Cloud Framework for Financial Services](https://cloud.ibm.com/docs/framework-financial-services?topic=framework-financial-services-about). See the [Example for IBM Cloud Framework for Financial Services](/examples/fscloud/) for logic that uses this module.

:exclamation: **Exception:** The Databases for etcd DB service is not yet Financial services validated. Therefore, the infrastructure that is deployed by this module is also not validated with the Framework for Financial Services. For more information, see the list of [Financial Services Validated services](https://cloud.ibm.com/docs/framework-financial-services?topic=framework-financial-services-vpc-architecture-about#financial-services-validated-services).

The default values in this profile were scanned by [IBM Code Risk Analyzer (CRA)](https://cloud.ibm.com/docs/code-risk-analyzer-cli-plugin?topic=code-risk-analyzer-cli-plugin-cra-cli-plugin#terraform-command) for compliance with the IBM Cloud Framework for Financial Services profile that is specified by the IBM Security and Compliance Center. The scan passed for all applicable rules with one exception:

> rule-beb7b289-706b-4dc0-b01d-b1d15d4331e3: Check whether Databases for etcd network access is restricted to a specific IP range.

The IBM Cloud Framework for Financial Services mandates the application of an inbound network-based allowlist in front of the IBM Cloud Databases for (ICD) etcd instance. You can comply with this requirement by using the `cbr_rules` variable in the module, which can be used to create a narrow context-based restriction rule that is scoped to the etcd instance. CRA does not currently support checking for context-based restrictions, so you can ignore the failing rule after you set the context-based restriction.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_ibm"></a> [ibm](#requirement\_ibm) | >= 1.54.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_etcd_db"></a> [etcd\_db](#module\_etcd\_db) | ../../ | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admin_pass"></a> [admin\_pass](#input\_admin\_pass) | The password for the database administrator. If the admin password is null then the admin user ID cannot be accessed. More users can be specified in a user block. The admin password must be in the range of 10-32 characters. | `string` | `null` | no |
| <a name="input_auto_scaling"></a> [auto\_scaling](#input\_auto\_scaling) | Optional rules to allow the database to increase resources in response to usage. Only a single autoscaling block is allowed. Make sure you understand the effects of autoscaling, especially for production environments. See https://cloud.ibm.com/docs/databases-for-etcd?topic=databases-for-etcd-autoscaling in the IBM Cloud Docs. | <pre>object({<br>    disk = object({<br>      capacity_enabled             = optional(bool, false)<br>      free_space_less_than_percent = optional(number, 10)<br>      io_above_percent             = optional(number, 90)<br>      io_enabled                   = optional(bool, false)<br>      io_over_period               = optional(string, "15m")<br>      rate_increase_percent        = optional(number, 10)<br>      rate_limit_mb_per_member     = optional(number, 3670016)<br>      rate_period_seconds          = optional(number, 900)<br>      rate_units                   = optional(string, "mb")<br>    })<br>    memory = object({<br>      io_above_percent         = optional(number, 90)<br>      io_enabled               = optional(bool, false)<br>      io_over_period           = optional(string, "15m")<br>      rate_increase_percent    = optional(number, 10)<br>      rate_limit_mb_per_member = optional(number, 114688)<br>      rate_period_seconds      = optional(number, 900)<br>      rate_units               = optional(string, "mb")<br>    })<br>  })</pre> | `null` | no |
| <a name="input_cbr_rules"></a> [cbr\_rules](#input\_cbr\_rules) | (Optional, list) List of CBR rules to create | <pre>list(object({<br>    description = string<br>    account_id  = string<br>    rule_contexts = list(object({<br>      attributes = optional(list(object({<br>        name  = string<br>        value = string<br>    }))) }))<br>    enforcement_mode = string<br>  }))</pre> | `[]` | no |
| <a name="input_configuration"></a> [configuration](#input\_configuration) | Database Configuration. | <pre>object({<br>    maxmemory                   = optional(number)<br>    maxmemory-policy            = optional(string)<br>    appendonly                  = optional(string)<br>    maxmemory-samples           = optional(number)<br>    stop-writes-on-bgsave-error = optional(string)<br>  })</pre> | `null` | no |
| <a name="input_etcd_version"></a> [etcd\_version](#input\_etcd\_version) | Version of the etcd instance to provision. If no value passed, the current ICD preferred version is used. | `string` | `null` | no |
| <a name="input_existing_kms_instance_guid"></a> [existing\_kms\_instance\_guid](#input\_existing\_kms\_instance\_guid) | The GUID of the Hyper Protect Crypto Services instance. | `string` | n/a | yes |
| <a name="input_kms_key_crn"></a> [kms\_key\_crn](#input\_kms\_key\_crn) | The root key CRN of the Hyper Protect Crypto Service (HPCS) to use for disk encryption. | `string` | n/a | yes |
| <a name="input_member_cpu_count"></a> [member\_cpu\_count](#input\_member\_cpu\_count) | Allocated dedicated CPU per-member. For shared CPU, set to 0. See the following doc for supported values: https://cloud.ibm.com/docs/databases-for-etcd?topic=databases-for-etcd-resources-scaling | `number` | `0` | no |
| <a name="input_member_disk_mb"></a> [member\_disk\_mb](#input\_member\_disk\_mb) | Allocated memory per-member. See the following doc for supported values: https://cloud.ibm.com/docs/databases-for-etcd?topic=databases-for-etcd-resources-scaling | `number` | `20480` | no |
| <a name="input_member_memory_mb"></a> [member\_memory\_mb](#input\_member\_memory\_mb) | Allocated memory per-member. See the following doc for supported values: https://cloud.ibm.com/docs/databases-for-etcd?topic=databases-for-etcd-resources-scaling | `number` | `1024` | no |
| <a name="input_members"></a> [members](#input\_members) | Allocated number of members. Members can be scaled up but not down. | `number` | `3` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the etcd\_db instance | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The region where you want to deploy your instance. Must be the same region as the Hyper Protect Crypto Services instance. | `string` | `"us-south"` | no |
| <a name="input_resource_group_id"></a> [resource\_group\_id](#input\_resource\_group\_id) | The resource group ID where the etcd\_db instance will be created. | `string` | n/a | yes |
| <a name="input_service_credential_names"></a> [service\_credential\_names](#input\_service\_credential\_names) | Map of name, role for service credentials that you want to create for the database | `map(string)` | `{}` | no |
| <a name="input_skip_iam_authorization_policy"></a> [skip\_iam\_authorization\_policy](#input\_skip\_iam\_authorization\_policy) | Set to true to skip the creation of an IAM authorization policy that permits all etcd database instances in the given resource group to read the encryption key from the Hyper Protect or Key Protect instance passed in var.existing\_kms\_instance\_guid. If set to 'false', a value must be passed for var.existing\_kms\_instance\_guid. No policy is created if var.kms\_encryption\_enabled is set to 'false'. | `bool` | `false` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Optional list of tags to be added to the etcd instance. | `list(any)` | `[]` | no |
| <a name="input_users"></a> [users](#input\_users) | A list of users that you want to create on the database. Multiple blocks are allowed. The user password must be in the range of 10-32 characters. Be warned that in most case using IAM service credentials (via the var.service\_credential\_names) is sufficient to control access to the etcd instance. This blocks creates native etcd database users, more info on that can be found here https://cloud.ibm.com/docs/databases-for-etcd?topic=databases-for-etcd-user-management&interface=ui | <pre>list(object({<br>    name     = string<br>    password = string # pragma: allowlist secret<br>    type     = string # "type" is required to generate the connection string for the outputs.<br>    role     = optional(string)<br>  }))</pre> | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cbr_rule_ids"></a> [cbr\_rule\_ids](#output\_cbr\_rule\_ids) | CBR rule ids created to restrict etcd db |
| <a name="output_crn"></a> [crn](#output\_crn) | etcd db instance crn |
| <a name="output_guid"></a> [guid](#output\_guid) | etcd db instance guid |
| <a name="output_hostname"></a> [hostname](#output\_hostname) | etcd db instance hostname |
| <a name="output_id"></a> [id](#output\_id) | etcd db instance id |
| <a name="output_port"></a> [port](#output\_port) | etcd db instance port |
| <a name="output_service_credentials_json"></a> [service\_credentials\_json](#output\_service\_credentials\_json) | Service credentials json map |
| <a name="output_service_credentials_object"></a> [service\_credentials\_object](#output\_service\_credentials\_object) | Service credentials object |
| <a name="output_version"></a> [version](#output\_version) | etcd db instance version |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->