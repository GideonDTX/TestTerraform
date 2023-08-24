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
    # for cluster autscaler to run
    "../oke-np-sys1"
  ]
}

inputs = {
  region           = local.region_vars.locals.region
  compartment_id   = local.env_vars.locals.compartment_id
  compartment_name = local.env_vars.locals.compartment_name
  vcn_id           = dependency.vcn.outputs.id
  oke_name         = dependency.cluster.outputs.name
  workers_nsg_id   = dependency.cluster.outputs.network_security_groups["workers"].id
  data_subnet_id   = dependency.vcn.outputs.subnets["data1"].id
}
