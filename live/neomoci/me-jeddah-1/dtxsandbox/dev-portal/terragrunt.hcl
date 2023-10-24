locals {
  globals = yamldecode(file(find_in_parent_folders("globals.yaml")))

  cloud_vars  = read_terragrunt_config(find_in_parent_folders("cloud.hcl"))
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  env_vars    = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  stack_vars  = yamldecode(file("stack.yaml"))
}

terraform {
  source = "git::git@github.com:Invicara/devops-dev-portal.git//modules/invicara/dev-portal?ref=${local.stack_vars.version}"
}

include "root" {
  path = find_in_parent_folders()
}

inputs = {
  env_name            = local.env_vars.locals.environment
  dev_hostname        = local.env_vars.locals.hostnames.dev
  npm_hostname        = local.env_vars.locals.hostnames.npm
  devportal_version   = local.stack_vars.version
  container_repo_host = local.cloud_vars.locals.container_repo_host
  dev_image_name      = "dev-portal-mirrana"
  enable_devadmin     = true
  devadmin_hostname   = local.env_vars.locals.hostnames.devadmin
}
