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
  name             = "mirrana.ai"
}
