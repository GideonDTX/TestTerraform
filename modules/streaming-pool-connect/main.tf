terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
    }

    kubectl = {
      source  = "gavinbunney/kubectl"
    }
  }
}

# locals
locals {
  # network labels for easy reading (and 'all' for consistency)
  icmp     = "1"
  tcp      = "6"
  udp      = "17"
  anyproto = "all"
  anywhere = "0.0.0.0/0"

  # icmp labels
  icmp_types = {
    echo_reply    = 0
    dest_unreach  = 3
    source_quench = 4
    echo_request  = 8
    time_exceeded = 11
  }
}

# datasource
data "oci_identity_tenancy" "this" {
  tenancy_id = local.service_id.tenancy
}

# nodepools
data "oci_containerengine_node_pools" "this" {
  compartment_id = var.compartment_id
  cluster_id     = var.cluster_id
  state          = ["ACTIVE", "UPDATING"]
}

# kubeconf
data "oci_containerengine_cluster_kube_config" "this" {
  cluster_id = var.cluster_id
}

# # this the correct provider when the VPN is in place
# provider "kubectl" {
#   host                   = yamldecode(data.oci_containerengine_cluster_kube_config.this.content).clusters[0].cluster.server
#   cluster_ca_certificate = base64decode(yamldecode(data.oci_containerengine_cluster_kube_config.this.content).clusters[0].cluster.certificate-authority-data)
#   exec {
#     api_version = yamldecode(data.oci_containerengine_cluster_kube_config.this.content).users[0].user.exec.apiVersion
#     command     = yamldecode(data.oci_containerengine_cluster_kube_config.this.content).users[0].user.exec.command
#     args        = yamldecode(data.oci_containerengine_cluster_kube_config.this.content).users[0].user.exec.args
#   }
# }

provider "kubectl" {
  config_path    = "~/.kube/config"
  config_context = "${var.cluster_name}-bastion"
}

# resources
resource "oci_core_network_security_group" "oss_pool" {
  display_name   = "${var.name}-oss-pool"
  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
}

resource "oci_core_network_security_group_security_rule" "oss_pool_egress_icmp" {
  for_each = local.icmp_types

  network_security_group_id = oci_core_network_security_group.oss_pool.id
  direction                 = "EGRESS"
  destination               = local.anywhere
  destination_type          = "CIDR_BLOCK"
  protocol                  = local.icmp

  icmp_options {
    type = each.value
  }
}

resource "oci_core_network_security_group_security_rule" "oss_pool_ingress_icmp" {
  for_each = local.icmp_types

  network_security_group_id = oci_core_network_security_group.oss_pool.id
  direction                 = "INGRESS"
  source                    = local.anywhere
  source_type               = "CIDR_BLOCK"
  protocol                  = local.icmp

  icmp_options {
    type = each.value
  }
}

# traffic from workers nsg to messaging
resource "oci_core_network_security_group_security_rule" "oss_pool_ingress_workers_to_messaging" {
  network_security_group_id = oci_core_network_security_group.oss_pool.id
  direction                 = "INGRESS"
  source                    = var.workers_nsg_id
  source_type               = "NETWORK_SECURITY_GROUP"
  protocol                  = local.tcp

  tcp_options {
    destination_port_range {
      min = 443
      max = 443
    }
  }
}

# traffic from bastion nsg to messaging
resource "oci_core_network_security_group_security_rule" "oss_pool_ingress_bastion_to_messaging" {
  network_security_group_id = oci_core_network_security_group.oss_pool.id
  direction                 = "INGRESS"
  source                    = var.bastion_nsg_id
  source_type               = "NETWORK_SECURITY_GROUP"
  protocol                  = local.tcp

  tcp_options {
    destination_port_range {
      min = 443
      max = 443
    }
  }
}

# traffic from bastion nsg to bootstrap
resource "oci_core_network_security_group_security_rule" "oss_pool_ingress_bastion_to_bootstrap" {
  network_security_group_id = oci_core_network_security_group.oss_pool.id
  direction                 = "INGRESS"
  source                    = var.bastion_nsg_id
  source_type               = "NETWORK_SECURITY_GROUP"
  protocol                  = local.tcp

  tcp_options {
    destination_port_range {
      min = 9092
      max = 9092
    }
  }
}

# traffic from workers nsg to bootstrap
resource "oci_core_network_security_group_security_rule" "oss_pool_ingress_workers_to_bootstrap" {
  network_security_group_id = oci_core_network_security_group.oss_pool.id
  direction                 = "INGRESS"
  source                    = var.workers_nsg_id
  source_type               = "NETWORK_SECURITY_GROUP"
  protocol                  = local.tcp

  tcp_options {
    destination_port_range {
      min = 9092
      max = 9092
    }
  }
}

# traffic from neomvpn nsg to messaging
resource "oci_core_network_security_group_security_rule" "oss_pool_ingress_neomvpn_to_messaging" {
  network_security_group_id = oci_core_network_security_group.oss_pool.id
  direction                 = "INGRESS"
  source                    = var.neom_vpn_cidr
  source_type               = "CIDR_BLOCK"
  protocol                  = local.tcp

  tcp_options {
    destination_port_range {
      min = 443
      max = 443
    }
  }
}

# traffic from neomvpn nsg to bootstrap
resource "oci_core_network_security_group_security_rule" "oss_pool_ingress_neomvpn_to_bootstrap" {
  network_security_group_id = oci_core_network_security_group.oss_pool.id
  direction                 = "INGRESS"
  source                    = var.neom_vpn_cidr
  source_type               = "CIDR_BLOCK"
  protocol                  = local.tcp

  tcp_options {
    destination_port_range {
      min = 9092
      max = 9092
    }
  }
}

# traffic from neomciscovpn nsg to messaging
resource "oci_core_network_security_group_security_rule" "oss_pool_ingress_neomciscovpn_to_messaging" {
  network_security_group_id = oci_core_network_security_group.oss_pool.id
  direction                 = "INGRESS"
  source                    = var.neom_cisco_vpn_cidr
  source_type               = "CIDR_BLOCK"
  protocol                  = local.tcp

  tcp_options {
    destination_port_range {
      min = 443
      max = 443
    }
  }
}

# traffic from neomciscovpn nsg to bootstrap
resource "oci_core_network_security_group_security_rule" "oss_pool_ingress_neomciscovpn_to_bootstrap" {
  network_security_group_id = oci_core_network_security_group.oss_pool.id
  direction                 = "INGRESS"
  source                    = var.neom_cisco_vpn_cidr
  source_type               = "CIDR_BLOCK"
  protocol                  = local.tcp

  tcp_options {
    destination_port_range {
      min = 9092
      max = 9092
    }
  }
}

resource "oci_streaming_stream_pool" "this" {
  compartment_id = var.compartment_id
  name           = var.name

  kafka_settings {
    auto_create_topics_enable = true
    log_retention_hours       = var.log_retention_hours
    num_partitions            = var.num_partitions
  }

  private_endpoint_settings {
    subnet_id           = var.subnet_id
    nsg_ids             = [
      oci_core_network_security_group.oss_pool.id,
    ]
  }
}

resource "oci_streaming_connect_harness" "this" {
  compartment_id = var.compartment_id
  name           = var.name
}

resource "oci_identity_policy" "this" {
  name           = "${var.name}-policy"
  description    = "allow ${local.service_id.group} permissions to streaming"
  compartment_id = var.compartment_id

  statements = [
    "Allow group ${local.service_id.group} to manage connect-harness in compartment ${var.compartment_name} where target.connectharness.id = '${oci_streaming_connect_harness.this.id}'",
    "Allow group ${local.service_id.group} to manage streams in compartment ${var.compartment_name} where target.streampool.id = '${oci_streaming_stream_pool.this.id}'",
    "Allow group ${local.service_id.group} to use stream-push in compartment ${var.compartment_name} where target.streampool.id = '${oci_streaming_stream_pool.this.id}'",
    "Allow group ${local.service_id.group} to use stream-pull in compartment ${var.compartment_name} where target.streampool.id = '${oci_streaming_stream_pool.this.id}'",
  ]
}

resource "kubectl_manifest" "oss-external-secret" {
  yaml_body = <<-EOT
    apiVersion: external-secrets.io/v1beta1
    kind: ExternalSecret
    metadata:
      name: oss
      namespace: ${var.kubernetes_namespace}
    spec:
      refreshInterval: "5m"
      secretStoreRef:
        kind: ClusterSecretStore
        name: oci-vault-${var.cluster_name}
      target:
        name: oss
        creationPolicy: Owner
        template:
          type: Opaque
          data:
            OCI_STREAM_BOOTSTRAP: "${join(",", oci_streaming_stream_pool.this.kafka_settings[*].bootstrap_servers)}"
            OCI_STREAM_USERNAME: "${data.oci_identity_tenancy.this.name}/{{ .username }}/${oci_streaming_stream_pool.this.id}"
            OCI_STREAM_PASSWORD: "{{ .auth_token }}"
            OCI_STREAM_CONNECT_ID: "${oci_streaming_connect_harness.this.id}"
      dataFrom:
        - extract:
            key: ${var.service_id_secret}
  EOT
}