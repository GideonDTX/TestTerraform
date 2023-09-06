locals {
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  env_vars    = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  approved_senders = [
    "do-not-reply-sandbox@mirrana.io"
  ]
}

terraform {
  source = "${get_parent_terragrunt_dir()}/../modules//platform-base"
}

include "root" {
  path = find_in_parent_folders()
}

dependency "vcn" {
  config_path = "../vcn"

  mock_outputs_allowed_terraform_commands = [
    "validate"
  ]
  mock_outputs = {
    id             = "fake-id"
    name           = "fake-name"
    compartment_id = "fake-compartment-id"
    subnets        = {
      subnet1 = {
        id   = "ABC"
        tier = "app"
        type = "private"
      }
    }
    bastion_nsg_id = "XXX"
  }
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
    "../vcn",
    "../oke-cluster",
  ]
}

inputs = {
  region                = local.region_vars.locals.region
  compartment_id        = local.env_vars.locals.compartment_id
  shared_compartment_id = local.env_vars.locals.shared_compartment_id
  compartment_name      = local.env_vars.locals.compartment_name
  vcn_id                = dependency.vcn.outputs.id
  cluster_id            = dependency.cluster.outputs.id
  cluster_name          = dependency.cluster.outputs.name
  kubernetes_namespace  = dependency.cluster.outputs.name
  service_id_secret     = local.env_vars.locals.service_id_secret
  approved_senders      = local.approved_senders
  dns_names             = local.env_vars.locals.dns_names
}
