locals {
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  env_vars    = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  stack_vars  = read_terragrunt_config("stack.hcl")
}

terraform {
  source = "git::git@github.com:Invicara/PlatformConsoleApp.git//terraform/modules/invicara/platform-console-app?ref=${local.stack_vars.locals.version}"
}

include "root" {
  path = find_in_parent_folders()
}

inputs = {
  env_name            = local.env_vars.locals.environment
  hostname            = local.env_vars.locals.dns_names.app
  deploy_version      = local.stack_vars.locals.version
  container_repo_host = local.region_vars.locals.container_repo_host
}
