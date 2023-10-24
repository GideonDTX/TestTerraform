locals {
  globals = yamldecode(file(find_in_parent_folders("globals.yaml")))

  cloud_vars  = read_terragrunt_config(find_in_parent_folders("cloud.hcl"))
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  env_vars    = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  stack_vars  = yamldecode(file("stack.yaml"))
}

terraform {
  source = "git::git@github.com:Invicara/devops-platformplugins.git//modules/invicara/platformplugins?ref=${local.stack_vars.version}"
}

include "root" {
  path = find_in_parent_folders()
}

inputs = {
  env_name                = local.env_vars.locals.environment
  hostname                = local.env_vars.locals.hostnames.app
  invicara_mode           = local.env_vars.locals.mode
  platformplugins_version = local.stack_vars.version
  container_repo_host     = local.region_vars.locals.container_repo_host
}
