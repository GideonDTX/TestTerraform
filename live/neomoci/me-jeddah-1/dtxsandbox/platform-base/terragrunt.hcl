locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  approved_senders = [
    "do-not-reply-qa1@sa.invicara.com"
  ]
}

terraform {
  source = "${get_parent_terragrunt_dir()}/../modules//platform-base"
}

include "root" {
  path = find_in_parent_folders()
}

dependencies {
  paths = [
    "../vcn",
  ]
}

inputs = {
  region           = local.region_vars.locals.region
  compartment_id   = local.env_vars.locals.compartment_id
  oke_name         = local.env_vars.locals.environment
  env_name         = local.env_vars.locals.environment
  kubes_namespace  = local.env_vars.locals.environment
  approved_senders = local.approved_senders
}
