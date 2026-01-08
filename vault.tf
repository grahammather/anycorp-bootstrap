# Bootstraps Vault auth for management workspace, so the management workspace can provision Vault roles for Applications that it onboards
# PREREQUISITE:
#  - Vault Operator policy. Created by hand during initial setup when following the HVD: https://developer.hashicorp.com/validated-designs/vault-operating-guides-adoption/initial-configuration

# Enables the jwt auth backend in Vault at the given path,
# and tells it where to find TFC's OIDC metadata endpoints.
#
# https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/jwt_auth_backend


# this could also be imported if it's already got roles in it
resource "vault_jwt_auth_backend" "tfc_jwt" {
  path               = local.vault_jwt_auth_path
  type               = "jwt"
  oidc_discovery_url = "https://${local.vault_jwt_tfe_hostname}"
  bound_issuer       = "https://${local.vault_jwt_tfe_hostname}"

  # If you are using TFE with custom / self-signed CA certs you may need to provide them via the
  # below argument as a string in PEM format.
  #
  # oidc_discovery_ca_pem = "my CA certs as PEM"
}

# tfc workspace run policy - TFE workspaces must be able to renew and revoke their own tokens
resource "vault_policy" "tfc_policy" {
  name = "tfc-policy"

  policy = <<EOT
# Allow tokens to query themselves
path "auth/token/lookup-self" {
  capabilities = ["read"]
}

# Allow tokens to renew themselves
path "auth/token/renew-self" {
    capabilities = ["update"]
}

# Allow tokens to revoke themselves
path "auth/token/revoke-self" {
    capabilities = ["update"]
}
EOT
}

# Creates a role for the jwt auth backend and uses bound claims
# - Allows all workspaces in the admin org the same level of access to the Vault, as defined by the local.tfe_vault_policy value
#
# https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/jwt_auth_backend_role
resource "vault_jwt_auth_backend_role" "tfc_management_role" {
  backend        = vault_jwt_auth_backend.tfc_jwt.path

  role_name      = local.tfe_vault_role
  token_policies = [vault_policy.tfc_policy.name, local.tfe_vault_policy] # TFE can act as an operator in order to provision Vault resources

  bound_audiences   = [local.tfe_vault_audience]
  bound_claims_type = "glob"
  bound_claims = {
    sub = "organization:${local.tfe_admin_org}:project:${local.tfe_admin_project}:workspace:*:run_phase:*"
  }
  user_claim = "terraform_full_workspace"
  role_type  = "jwt"
  token_ttl  = 2400
}
