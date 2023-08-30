locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

terraform {
  source = "${get_parent_terragrunt_dir()}/../modules//dns-and-email"
}

include "root" {
  path = find_in_parent_folders()
}

inputs = {
  compartment_id   = local.env_vars.locals.compartment_id
  compartment_name = local.env_vars.locals.compartment_name
  name             = "mirrana.dev"

  groups_allowed_to_update = [
    {
      name = "TONOMUS_DTX_PaaS-Sandbox_OKE_Workers_DynamicGroup"
      type = "dynamic-group"
    }
  ]
}
