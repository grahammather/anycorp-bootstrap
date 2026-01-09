data "tfe_organizations" "this" {}

data "tfe_organization" "this" {
  name = data.tfe_organizations.this.names[0]

  lifecycle {
    precondition {
      condition     = length(data.tfe_organizations.this.names) == 1
      error_message = "Expected exactly one TFE organization for this token, but found ${length(data.tfe_organizations.this.names)}."
    }
  }
}

data "tfe_project" "admin_project" {
  name = local.tfe_admin_project
  organization = data.tfe_organization.this.name
}

data "tfe_workspace" "bootstrap" {
  name = local.tfe_bootstrap_workspace
  organization = data.tfe_organization.this.name
}

# it's a PITA to set up VCS connections from TFE. 
# create the repo and connected workspace first, then reference the ws as data here.
data "tfe_workspace" "management" {
  name = local.tfe_management_workspace
  organization = data.tfe_organization.this.name
}

resource "tfe_workspace_variable_set" "management_vault" {
  variable_set_id = tfe_variable_set.vault.id
  workspace_id = data.tfe_workspace.management.id
}

#================
# Varsets

# Vault Auth
# The following variables must be set to allow runs
# to authenticate to Vault.
#
# https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/resources/variable

resource "tfe_variable_set" "vault" {
  name          = local.tfe_vault_varset_name
  description   = "Enables a workspace to use the Vault provider."
  organization  = data.tfe_organization.this.name
}

resource "tfe_variable" "enable_vault_provider_auth" {
  variable_set_id = tfe_variable_set.vault.id

  key      = "TFC_VAULT_PROVIDER_AUTH"
  value    = "true"
  category = "env"

  description = "Enable the Workload Identity integration for Vault."
}

resource "tfe_variable" "tfc_vault_addr" {
  variable_set_id = tfe_variable_set.vault.id

  key       = "TFC_VAULT_ADDR"
  value     = local.vault_url
  category  = "env"
  sensitive = true

  description = "The address of the Vault instance runs will access."
}

# The following variables are optional; uncomment the ones you need!
# Required for TFC

resource "tfe_variable" "tfc_vault_namespace" {
  variable_set_id = tfe_variable_set.vault.id

  key      = "TFC_VAULT_NAMESPACE"
  value    = local.vault_namespace
  category = "env"

  description = "The Vault namespace to use, if not using the default"
}

resource "tfe_project_variable_set" "vault_varset" {
  variable_set_id = tfe_variable_set.vault.id
  project_id = data.tfe_project.admin_project.id
}

resource "tfe_variable" "tfe_bootstrap_vault_role" {
  workspace_id = data.tfe_workspace.bootstrap.id

  key      = "TFC_VAULT_RUN_ROLE"
  value    = local.tfe_vault_role
  category = "env"

  description = "The Vault role runs will use to authenticate."
}

resource "tfe_variable" "tfe_management_vault_role" {
  workspace_id = data.tfe_workspace.management.id

  key      = "TFC_VAULT_RUN_ROLE"
  value    = local.tfe_vault_role
  category = "env"

  description = "The Vault role runs will use to authenticate."
}

resource "tfe_variable" "tfc_vault_auth_path" {
  variable_set_id = tfe_variable_set.vault.id

  key      = "TFC_VAULT_AUTH_PATH"
  value    = local.vault_jwt_auth_path
  category = "env"

  description = "The path where the jwt auth backend is mounted, if not using the default"
}

# resource "tfe_variable" "tfe_vault_audience" {
#   variable_set_id = tfe_variable_set.vault.id

#   key      = "TFC_VAULT_WORKLOAD_IDENTITY_AUDIENCE"
#   value    = var.tfe_vault_audience
#   category = "env"

#   description = "The value to use as the audience claim in run identity tokens"
# }

# resource "tfe_variable" "tfc_vault_encoded_cacert" {
#   variable_set_id = tfe_variable_set.vault.id

#   key = "TFC_VAULT_ENCODED_CACERT"

#   # Replace this with the name and path to your certificate
#   value     = filebase64("${path.module}/my-cacert.cer")
#   category  = "env"
#   sensitive = true

#   description = "A Base64 encoded CA certificate to use when authenticating with Vault"
# }

# The following is an example of the naming format used to define variables for
# additional configurations. Additional required configuration values must also
# be supplied in this same format, as well as any desired optional configuration
# values.
#
# Additional configurations can be used to uniquely authenticate multiple aliases
# of the same provider in a workspace, with different roles/permissions in different
# accounts or regions.
#
# See https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials/specifying-multiple-configurations
# for more details on specifying multiple configurations.
#
# See https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials/vault-configuration#specifying-multiple-configurations
# for specific requirements and details for the Vault provider.

# resource "tfe_variable" "enable_vault_provider_auth_other_config" {
#   variable_set_id = tfe_variable_set.vault.id

#   key      = "TFC_VAULT_PROVIDER_AUTH_other_config"
#   value    = "true"
#   category = "env"

#   description = "Enable the Workload Identity integration for Vault for an additional configuration named other_config."
# }