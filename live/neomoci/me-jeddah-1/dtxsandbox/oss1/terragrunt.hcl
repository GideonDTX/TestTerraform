locals {
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  env_vars    = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

terraform {
  source = "${get_parent_terragrunt_dir()}/../modules//streaming-pool-connect"
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
  name                 = basename(get_terragrunt_dir())
  compartment_id       = local.env_vars.locals.compartment_id
  compartment_name     = local.env_vars.locals.compartment_name
  vcn_id               = dependency.vcn.outputs.id
  cluster_id           = dependency.cluster.outputs.id
  cluster_name         = dependency.cluster.outputs.name
  kubernetes_namespace = dependency.cluster.outputs.name
  subnet_id            = dependency.vcn.outputs.subnets["data1"].id
  workers_nsg_id       = dependency.cluster.outputs.network_security_groups["workers"].id
  bastion_nsg_id       = dependency.vcn.outputs.bastion_nsg_id
  service_id_secret    = local.env_vars.locals.service_id_secret
  neom_vpn_cidr        = local.region_vars.locals.neom_vpn_cidr
  neom_cisco_vpn_cidr  = local.region_vars.locals.neom_cisco_vpn_cidr
}
