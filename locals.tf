# Codify LZ management by explicitly specifying systems
locals {
  tfe_admin_org = "" # name of the org in TFE that's use to administrate the shared-tenant org
  tfe_admin_project = "" # the project that holds the bootstrap and management workspaces
  tfe_management_workspace = "" # the workspace in the admin org for the management repo that manages the shared-tenant org
  tfe_bootstrap_workspace = "" # the VCS workspace for this codebase. bootstraps the management workspace

  vault_url = "" # full URL including protocol https://vault.example.com/
  vault_namespace = "" # the namespace that workspaces in the shared tenancy org will authenticate to. Also the namespace that the management workspace authenticates to to configure shared tenant auth.
  tfe_vault_varset_name = "" # the name of the variable set that bootstrapped workspaces use to connect to the Vault 
  tfe_vault_policy = "" # Vault policy for the management workspace. Requires permissions to configure jwt auth mount. If you don't want to give TFE operator access, create another policy by hand during initial Vault setup, and use it here. The Vault HVD guides you through creating an "operator" policy, which could be used here.

  vault_jwt_auth_path = "jwt" # the mount path in Vault for the jwt auth method. only change this if there's already something mounted at /jwt
  vault_jwt_tfe_hostname = "" # the hostname of TFE. Vault calls back to this host in order to verify tokens.

  tfe_vault_audience = "vault.workload.identity" # Default workload identity setting. you probably don't need to change this
  tfe_vault_role = "" # this role is created in Vault for the bootstrap workspace
}