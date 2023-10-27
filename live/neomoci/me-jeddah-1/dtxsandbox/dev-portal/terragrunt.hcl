locals {
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  env_vars    = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  stack_vars  = read_terragrunt_config("stack.hcl")
}

terraform {
  source = "git::git@github.com:Invicara/devops-dev-portal.git//modules/invicara/dev-portal?ref=${local.stack_vars.locals.version}"
}

include "root" {
  path = find_in_parent_folders()
}

inputs = {
  env_name            = local.env_vars.locals.environment
  devportal_version   = local.stack_vars.locals.version
  container_repo_host = local.region_vars.locals.container_repo_host

  dev_image_name = "dev-portal-mirrana"
  dev_hostname   = local.env_vars.locals.dns_names.dev

  devadmin_hostname = local.env_vars.locals.dns_names.devadmin
  enable_devadmin   = true

  npm_hostname                 = local.env_vars.locals.dns_names.npm
  enable_npm_persisted_storage = true
}
