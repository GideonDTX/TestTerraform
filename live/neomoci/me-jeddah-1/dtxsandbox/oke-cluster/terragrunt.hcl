locals {
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  env_vars    = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  kubernetes_version = "v1.26.2"
}

terraform {
  source = "${get_parent_terragrunt_dir()}/../modules//oke-cluster"
}

include "root" {
  path = find_in_parent_folders()
}


inputs = {
  # cluster is named the same as the VCN which is named the same as the environment
  name               = "dtxTest"
  region_name        = local.region_vars.locals.region
  vcn_id             = "ocid1.vcn.oc1.me-jeddah-1.amaaaaaasj6bavyafrddny6slw24fcl6d3qsv5w52s4bgc4a647sb76rglha"
  compartment_id     = "ocid1.compartment.oc1..aaaaaaaaimjp3jzwblxkr2ptywfbb6zqt7k4ykvluue6g37gqiedf6yd5sqq"
  public_subnet_id   = "ocid1.subnet.oc1.me-jeddah-1.aaaaaaaaafdy22ritzpds5sglo4mmkrxau46rbsnzykg3d2osqifbit5vveq"
  private_subnet_id  = "ocid1.subnet.oc1.me-jeddah-1.aaaaaaaah7fd3dxist7pzucsolh4ps72tx2ss5342fkhkkcnfohtmtiroelq"
  data_subnet_cidr   = "ocid1.subnet.oc1.me-jeddah-1.aaaaaaaa7gwrfvb66nbsxmmokvs4z6zxzngo62juxzlnj6dqzgqxzumqsjua"
  kubernetes_version = local.kubernetes_version
  service_id_secret  = local.env_vars.locals.service_id_secret
  bastion_nsg_id     = "ocid1.securitylist.oc1.me-jeddah-1.aaaaaaaafiifmioa2fxidewjztpnzfbp2oekbjhdb3j4w7trrca5e74zn6xq"

  neom_vpn_cidr       = local.region_vars.locals.neom_vpn_cidr
  neom_cisco_vpn_cidr = local.region_vars.locals.neom_cisco_vpn_cidr
}
