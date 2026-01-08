# Use the TF_TOKEN_app_terraform_io to set a User Token to authenticate with HCP Terraform.

terraform {
  cloud {
    organization = "<your admin org>"

    workspaces {
      project = "Default Project"
      name    = "<bootstrap workspace>"
    }
  }
}
