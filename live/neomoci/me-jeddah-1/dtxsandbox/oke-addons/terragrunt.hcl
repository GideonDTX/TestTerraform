locals {
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  env_vars    = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

terraform {
  source = "${get_parent_terragrunt_dir()}/../modules//oke-addons"
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
    id                 = "fake-id"
    compartment_id     = "fake-compartment-id"
    public_subnet_ids  = ["fake-public-subnet-id"]
    private_subnet_ids = ["fake-private-subnet-id"]
    kms_key_id         = "fake-kms-key-id"
  }
}

dependency "cluster" {
  config_path = "../oke-cluster"

  mock_outputs_allowed_terraform_commands = [
    "validate"
  ]
  mock_outputs = {
    name               = "fake-name"
    public_subnet_ids  = ["fake-public-subnet-id"]
    private_subnet_ids = ["fake-private-subnet-id"]
  }
}

dependencies {
  paths = [
    "../vcn",
    "../oke-cluster",
    "../oke-calico",
    # for cluster autscaler to run
    "../oke-np-sys1"
  ]
}

inputs = {
  region               = local.region_vars.locals.region
  compartment_id       = dependency.vcn.outputs.compartment_id
  compartment_name     = local.env_vars.locals.compartment_name
  vcn_id               = dependency.vcn.outputs.id
  cluster_id           = dependency.cluster.outputs.id
  cluster_name         = dependency.cluster.outputs.name
  workers_nsg_id       = dependency.cluster.outputs.network_security_groups["workers"].id
  loadbalancers_nsg_id = dependency.cluster.outputs.network_security_groups["loadbalancers"].id
  data_subnet_id       = dependency.vcn.outputs.subnets["data1"].id
  service_id_secret    = local.env_vars.locals.service_id_secret
}
