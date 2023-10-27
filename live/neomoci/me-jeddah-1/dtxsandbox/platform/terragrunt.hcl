locals {
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  env_vars    = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  stack_vars  = read_terragrunt_config("stack.hcl")
}

terraform {
  source = "git::git@github.com:Invicara/devops-platform.git//modules/invicara/platform?ref=${local.stack_vars.locals.version}"
}

include "root" {
  path = find_in_parent_folders()
}

inputs = {
  env_name            = local.env_vars.locals.environment
  app_hostname        = local.env_vars.locals.dns_names.app
  api_hostname        = local.env_vars.locals.dns_names.api
  invicara_mode       = "production"
  platform_version    = local.stack_vars.locals.version
  container_repo_host = local.region_vars.locals.container_repo_host
}
