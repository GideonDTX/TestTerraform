locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

terraform {
  source = "${get_parent_terragrunt_dir()}/../modules//container-registry"
}

include "root" {
  path = find_in_parent_folders()
}

inputs = {
  compartment_id   = local.env_vars.locals.compartment_id
  compartment_name = local.env_vars.locals.compartment_name
  env_name         = local.env_vars.locals.environment
  access_groups  = {
    readonly = [
      "TONOMUS_DTX_PaaS-Dev_Read",
      "TONOMUS_DTX_Paas-Prod_Read",
    ]
  }

  repositories = [
    ### Images Hosted at DockerHub - These are replicated because of docker.io service limits
    {
      name = "dtx/library/ubuntu",
    },
    {
      name = "dtx/library/neo4j",
    },
    {
      name = "dtx/calico/apiserver",
    },
    {
      name = "dtx/calico/cni",
    },
    {
      name = "dtx/calico/csi",
    },
    {
      name = "dtx/calico/kube-controllers",
    },
    {
      name = "dtx/calico/node-driver-registrar",
    },
    {
      name = "dtx/calico/node",
    },
    {
      name = "dtx/calico/pod2daemon-flexvol",
    },
    {
      name = "dtx/calico/typha",
    },
    ### Images for Platform Services
    {
      name = "dtx/datasourcesvc",
    },
    {
      name = "dtx/datasourcesvc-migrations",
    },
    {
      name = "dtx/filesvc",
    },
    {
      name = "dtx/filesvc-migrations",
    },
    {
      name = "dtx/ipaplugins",
    },
    {
      name = "dtx/itemsvc",
    },
    {
      name = "dtx/itemsvc-worker",
    },
    {
      name = "dtx/itemsvc-migrations",
    },
    {
      name = "dtx/itemsvc-telemetry-worker",
    },
    {
      name = "dtx/itemsvc-rdbms-migrations",
    },
    {
      name = "dtx/manage-admin",
    },
    {
      name = "dtx/notificationsvc",
    },
    {
      name = "dtx/notificationsvc-migrations",
    },
    {
      name = "dtx/passportsvc",
    },
    {
      name = "dtx/passportsvc-migrations",
    },
    {
      name = "dtx/platformiamsvc",
    },
    {
      name = "dtx/platformiamsvc-migrations",
    },
    {
      name = "dtx/platform-console-app",
    },
    {
      name = "dtx/platform-reference-app",
    },
    {
      name = "dtx/graphicssvc",
    },
    {
      name = "dtx/platform-kafka-connect",
    },
    {
      name = "dtx/objectmodelapisvc",
    },
    {
      name = "dtx/objectmodelapisvc-migrations",
    },
    {
      name = "dtx/api-gateway",
    },
    {
      name = "dtx/api-gateway-migrations",
    },
    {
      name = "dtx/pdom-cli",
    },
    {
      name = "dtx/ipa-dev",
    },
    {
      name = "dtx/scriptmanager",
    },
    {
      name = "dtx/scriptmanager-migrations",
    },
    {
      name = "dtx/scriptworker",
    },
    {
      name = "dtx/eventtransformsvc",
    },
    ### Images for TwinitDevVSCodeExt
    {
      name = "dtx/twinit-dev-vscode-ext",
    },
    ### Images for DevPotal
    {
      name = "dtx/dev-portal-mirrana",
    },
    {
      name = "dtx/npm-registry",
    },
    {
      name = "dtx/dev-access-mgmt",
    },
  ]
}
