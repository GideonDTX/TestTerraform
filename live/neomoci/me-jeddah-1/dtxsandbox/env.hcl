locals {
  environment           = "dtxsandbox"
  compartment_name      = "DTX_PaaS-Sandbox"
  compartment_id        = "ocid1.compartment.oc1..aaaaaaaabavsmgb2to2nczlztwy5w3lcopfajpf5hvum4tcz2i2bzt7pd77a"
  shared_compartment_id = "ocid1.compartment.oc1..aaaaaaaaelhj7c2mf6thajka6uhgccy6ps7j5a2nssvzrvpul3ypaodavflq"
  service_id_secret     = "serviceid_dtxnonprod_at_neom_dot_com"
  cluster_name          = "dtxsandbox"
  cluster_workers_group = "TONOMUS_DTX_PaaS-Sandbox_OKE_Workers_DynamicGroup"
  allowed_domain_zones  = [
    "mirrana.io",
    "mirrana.dev",
  ]
  dns_names   = {
    app      = "sandbox.mirrana.io"
    api      = "sandbox-api.mirrana.io"
    id       = "sandbox-id.mirrana.io"
    dev      = "sandbox.mirrana.dev"
    devadmin = "sandbox-admin.mirrana.dev"
    npm      = "sandbox-npm.mirrana.dev"
  }
}
