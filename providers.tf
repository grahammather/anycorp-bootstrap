terraform {
  required_version = "~> 1.7"

  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = "0.71.0"
    }
    vault = {
      source = "hashicorp/vault"
      version = "5.6.0"
    }
  }
}

provider "vault" {
  address = local.vault_url
  namespace = local.vault_namespace
}

provider "tfe" {}