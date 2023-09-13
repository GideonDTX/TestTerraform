locals {
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  env_vars    = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  version = "v4.4.25"
}

terraform {
  source = "${get_parent_terragrunt_dir()}/../modules//neo4j"
}

include "root" {
  path = find_in_parent_folders()
}

dependency "cluster" {
  config_path = "../oke-cluster"

  mock_outputs_allowed_terraform_commands = [
    "validate"
  ]
  mock_outputs = {
    id                      = "fake-id"
    name                    = "fake-name"
    compartment_id          = "fake-compartment-id"
    private_subnet_id       = "fake-private-subnet-id"
    network_security_groups = {
      workers = {
        id   = "ABC"
      }
    }
    ssh_public_key = "fake-ssh-key"
  }
}

dependencies {
  paths = [
    "../oke-cluster",
  ]
}

inputs = {
  helm_chart_version   = local.version
  compartment_id       = local.env_vars.locals.compartment_id
  compartment_name     = local.env_vars.locals.compartment_name
  cluster_id           = dependency.cluster.outputs.id
  cluster_name         = dependency.cluster.outputs.name
  kubernetes_namespace = local.env_vars.locals.environment
  container_repo_host  = local.region_vars.locals.container_repo_host
}
