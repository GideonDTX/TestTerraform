terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
    }
    tls = {
      source  = "hashicorp/tls"
    }
  }
}

locals {
  # network labels
  anywhere = "0.0.0.0/0"

  # protocol labels
  icmp     = "1"
  tcp      = "6"
  udp      = "17"
  anyproto = "all"

  # icmp labels
  icmp_types = {
    echo_reply    = 0
    dest_unreach  = 3
    source_quench = 4
    echo_request  = 8
    time_exceeded = 11
  }

  # cidr allocations
  services_cidr = "172.20.0.0/16"
  pods_cidr     = "172.21.0.0/16"
}

# datasources
data "oci_core_vcn" "this" {
  vcn_id = var.vcn_id
}

# data sources
data "oci_core_services" "this" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}

# ssh key for node groups
resource "tls_private_key" "this" {
  algorithm = "ED25519"
}

# cluster
resource "oci_containerengine_cluster" "this" {
  name           = var.name
  type           = "ENHANCED_CLUSTER"
  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id

  kubernetes_version = var.kubernetes_version

  endpoint_config {
    is_public_ip_enabled = false
    nsg_ids              = [oci_core_network_security_group.api.id]
    subnet_id            = var.private_subnet_id
  }

  cluster_pod_network_options {
    cni_type = "FLANNEL_OVERLAY"
  }

  options {
    add_ons {
      is_kubernetes_dashboard_enabled = false
      is_tiller_enabled               = false
    }

    admission_controller_options {
      is_pod_security_policy_enabled = false
    }

    kubernetes_network_config {
      services_cidr = local.services_cidr
      pods_cidr     = local.pods_cidr
    }

    persistent_volume_config {}

    service_lb_config {}

    service_lb_subnet_ids = [var.public_subnet_id]
  }
}

### load balancers security group
### Notes: https://docs.oracle.com/en-us/iaas/Content/ContEng/Concepts/contengnetworkconfig.htm#securitylistconfig__security_rules_for_load_balancers

resource "oci_core_network_security_group" "loadbalancers" {
  display_name   = "${var.name}-oke-loadbalancers"
  compartment_id = var.compartment_id
  vcn_id         = data.oci_core_vcn.this.id
}

## load balancers ingress

resource "oci_core_network_security_group_security_rule" "loadbalancers_ingress_icmp" {
  for_each = local.icmp_types

  description = "allow incoming icmp for load balancers from anywhere/public"

  network_security_group_id = oci_core_network_security_group.loadbalancers.id
  direction                 = "INGRESS"
  source                    = local.anywhere
  source_type               = "CIDR_BLOCK"
  protocol                  = local.icmp

  icmp_options {
    type = each.value
  }
}

resource "oci_core_network_security_group_security_rule" "loadbalancers_ingress_http" {
  description = "allow incoming http from anywhere/internet"

  network_security_group_id = oci_core_network_security_group.loadbalancers.id
  direction                 = "INGRESS"
  source                    = local.anywhere
  source_type               = "CIDR_BLOCK"
  protocol                  = local.tcp

  tcp_options {
    destination_port_range {
      min = 80
      max = 80
    }
  }
}

resource "oci_core_network_security_group_security_rule" "loadbalancers_ingress_https" {
  description = "allow incoming https from anywhere/internet"

  network_security_group_id = oci_core_network_security_group.loadbalancers.id
  direction                 = "INGRESS"
  source                    = local.anywhere
  source_type               = "CIDR_BLOCK"
  protocol                  = local.tcp

  tcp_options {
    destination_port_range {
      min = 443
      max = 443
    }
  }
}

## load balancers egress

resource "oci_core_network_security_group_security_rule" "loadbalancers_egress_workers_kubeproxy_ports" {
  description = "allow outgoing proxy traffic to workers kubeproxy exposed ports"

  network_security_group_id = oci_core_network_security_group.loadbalancers.id
  direction                 = "EGRESS"
  destination               = oci_core_network_security_group.workers.id
  destination_type          = "NETWORK_SECURITY_GROUP"
  protocol                  = local.tcp

  tcp_options {
    destination_port_range {
      min = 30000
      max = 32767
    }
  }
}

resource "oci_core_network_security_group_security_rule" "loadbalancers_egress_workers_kubeproxy_health" {
  description = "allow outgoing proxy traffic to workers kubeproxy health port"

  network_security_group_id = oci_core_network_security_group.loadbalancers.id
  direction                 = "EGRESS"
  destination               = oci_core_network_security_group.workers.id
  destination_type          = "NETWORK_SECURITY_GROUP"
  protocol                  = local.tcp

  tcp_options {
    destination_port_range {
      min = 10256
      max = 10256
    }
  }
}

### api (kubernetes api)
### Notes: https://docs.oracle.com/en-us/iaas/Content/ContEng/Concepts/contengnetworkconfig.htm#securitylistconfig

resource "oci_core_network_security_group" "api" {
  display_name   = "${var.name}-oke-api"
  compartment_id = var.compartment_id
  vcn_id         = data.oci_core_vcn.this.id
}

## api ingress rules

resource "oci_core_network_security_group_security_rule" "api_ingress_icmp" {
  for_each = local.icmp_types

  description = "allow all icmp within the vcn"

  network_security_group_id = oci_core_network_security_group.api.id
  direction                 = "INGRESS"
  source                    = data.oci_core_vcn.this.cidr_block
  source_type               = "CIDR_BLOCK"
  protocol                  = local.icmp

  icmp_options {
    type = each.value
  }
}

resource "oci_core_network_security_group_security_rule" "api_ingress_6443" {
  description = "allow workers to communicate with api on 6443"

  network_security_group_id = oci_core_network_security_group.api.id
  direction                 = "INGRESS"
  source                    = oci_core_network_security_group.workers.id
  source_type               = "NETWORK_SECURITY_GROUP"
  protocol                  = local.tcp

  tcp_options {
    destination_port_range {
      min = 6443
      max = 6443
    }
  }
}

resource "oci_core_network_security_group_security_rule" "api_ingress_bastion_6443" {
  description = "allow workers to communicate with api on 6443"

  network_security_group_id = oci_core_network_security_group.api.id
  direction                 = "INGRESS"
  source                    = var.bastion_nsg_id
  source_type               = "NETWORK_SECURITY_GROUP"
  protocol                  = local.tcp

  tcp_options {
    destination_port_range {
      min = 6443
      max = 6443
    }
  }
}

resource "oci_core_network_security_group_security_rule" "api_ingress_12250" {
  description = "allow workers to communicate with api on 12250"

  network_security_group_id = oci_core_network_security_group.api.id
  direction                 = "INGRESS"
  source                    = oci_core_network_security_group.workers.id
  source_type               = "NETWORK_SECURITY_GROUP"
  protocol                  = local.tcp

  tcp_options {
    destination_port_range {
      min = 12250
      max = 12250
    }
  }
}

## api egress rules

resource "oci_core_network_security_group_security_rule" "api_egress_https_to_servicegw" {
  description = "allow outgoing https from api to service gateway"

  network_security_group_id = oci_core_network_security_group.api.id
  direction                 = "EGRESS"
  destination               = data.oci_core_services.this.services[0]["cidr_block"]
  destination_type          = "SERVICE_CIDR_BLOCK"
  protocol                  = local.tcp

  tcp_options {
    destination_port_range {
      min = 443
      max = 443
    }
  }
}

resource "oci_core_network_security_group_security_rule" "api_egress_workers" {
  description = "allow outgoing anything from api to worker nodes"

  network_security_group_id = oci_core_network_security_group.api.id
  direction                 = "EGRESS"
  destination               = oci_core_network_security_group.workers.id
  destination_type          = "NETWORK_SECURITY_GROUP"
  protocol                  = local.anyproto
}

### workers in the nodegroups
### https://docs.oracle.com/en-us/iaas/Content/ContEng/Concepts/contengnetworkconfig.htm#securitylistconfig

resource "oci_core_network_security_group" "workers" {
  display_name   = "${var.name}-oke-workers"
  compartment_id = var.compartment_id
  vcn_id         = data.oci_core_vcn.this.id
}

## workers ingress rules

resource "oci_core_network_security_group_security_rule" "workers_ingress_icmp" {
  for_each = local.icmp_types

  description = "allow all icmp within the vcn"

  network_security_group_id = oci_core_network_security_group.workers.id
  direction                 = "INGRESS"
  source                    = data.oci_core_vcn.this.cidr_block
  source_type               = "CIDR_BLOCK"
  protocol                  = local.icmp

  icmp_options {
    type = each.value
  }
}

resource "oci_core_network_security_group_security_rule" "workers_ingress_inter_node" {
  description = "all inter-node traffic is allowed to support kubernetes and network overlay"

  network_security_group_id = oci_core_network_security_group.workers.id
  direction                 = "INGRESS"
  source                    = oci_core_network_security_group.workers.id
  source_type               = "NETWORK_SECURITY_GROUP"
  protocol                  = local.anyproto
}

resource "oci_core_network_security_group_security_rule" "workers_ingress_api" {
  description = "all incoming traffic from api to workers is allowed"

  network_security_group_id = oci_core_network_security_group.workers.id
  direction                 = "INGRESS"
  source                    = oci_core_network_security_group.api.id
  source_type               = "NETWORK_SECURITY_GROUP"
  protocol                  = local.anyproto
}

## workers egress list

resource "oci_core_network_security_group_security_rule" "workers_egress_https" {
  description = "allow outgoing https from workers for platform services"

  network_security_group_id = oci_core_network_security_group.workers.id
  direction                 = "EGRESS"
  destination               = local.anywhere
  destination_type          = "CIDR_BLOCK"
  protocol                  = local.tcp

  tcp_options {
    destination_port_range {
      min = 443
      max = 443
    }
  }
}

resource "oci_core_network_security_group_security_rule" "workers_egress_inter_node" {
  description = "all inter-node traffic is allowed to support kubernetes and network overlay"

  network_security_group_id = oci_core_network_security_group.workers.id
  direction                 = "EGRESS"
  destination               = oci_core_network_security_group.workers.id
  destination_type          = "NETWORK_SECURITY_GROUP"
  protocol                  = local.anyproto
}

resource "oci_core_network_security_group_security_rule" "workers_egress_6443" {
  description = "allow workers to communicate with api on 6443"

  network_security_group_id = oci_core_network_security_group.workers.id
  direction                 = "EGRESS"
  destination               = oci_core_network_security_group.api.id
  destination_type          = "NETWORK_SECURITY_GROUP"
  protocol                  = local.tcp

  tcp_options {
    destination_port_range {
      min = 6443
      max = 6443
    }
  }
}

resource "oci_core_network_security_group_security_rule" "workers_egress_12250" {
  description = "allow workers to communicate with api on 12250"

  network_security_group_id = oci_core_network_security_group.workers.id
  direction                 = "EGRESS"
  destination               = oci_core_network_security_group.api.id
  destination_type          = "NETWORK_SECURITY_GROUP"
  protocol                  = local.tcp

  tcp_options {
    destination_port_range {
      min = 12250
      max = 12250
    }
  }
}

# note: this is actually redundant considering the above "all" rule for https, but we'll keep it in case
# the above rule changes at some point in the future
resource "oci_core_network_security_group_security_rule" "workers_egress_https_to_servicegw" {
  description = "allow outgoing https from workers to service gateway"

  network_security_group_id = oci_core_network_security_group.workers.id
  direction                 = "EGRESS"
  destination               = data.oci_core_services.this.services[0]["cidr_block"]
  destination_type          = "SERVICE_CIDR_BLOCK"
  protocol                  = local.tcp

  tcp_options {
    destination_port_range {
      min = 443
      max = 443
    }
  }
}
