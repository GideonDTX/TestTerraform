### Creates a mount target and NSGS to access
### This is one per cluster
### Create a filesystem per namespace and export unique paths to this mount point

# locals
locals {
  nfs_tcp_ports = {
    sunrpc = 111,
    nfs_2048 = 2048,
    nfs_2049 = 2049,
    nfs_2050 = 2050,
    nfs_2050 = 2051,
  }

  nfs_udp_ports = {
    sunrpc = 111,
    nfs    = 2048,
  }
}

resource "oci_core_network_security_group" "fss" {
  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "${var.cluster_name}-oke-fss"
}

# all icmp within the vcn is allowed
resource "oci_core_network_security_group_security_rule" "fss_ingress_rule_icmp" {
  for_each = local.icmp_types

  network_security_group_id = oci_core_network_security_group.fss.id
  direction                 = "INGRESS"
  source                    = data.oci_core_vcn.this.cidr_block
  source_type               = "CIDR_BLOCK"
  protocol                  = local.icmp

  icmp_options {
    type = each.value
  }
}

# all nfs tcp allowed from the cluster
resource "oci_core_network_security_group_security_rule" "fss_ingress_rule_nfs_tcp" {
  for_each = local.nfs_tcp_ports

  network_security_group_id = oci_core_network_security_group.fss.id
  direction                 = "INGRESS"
  source                    = var.workers_nsg_id
  source_type               = "NETWORK_SECURITY_GROUP"
  protocol                  = local.tcp

  tcp_options {
    destination_port_range {
      min = each.value
      max = each.value
    }
  }
}

# all nfs udp allowed from the cluster
resource "oci_core_network_security_group_security_rule" "fss_ingress_rule_nfs_udp" {
  for_each = local.nfs_tcp_ports

  network_security_group_id = oci_core_network_security_group.fss.id
  direction                 = "INGRESS"
  source                    = var.workers_nsg_id
  source_type               = "NETWORK_SECURITY_GROUP"
  protocol                  = local.udp

  udp_options {
    destination_port_range {
      min = each.value
      max = each.value
    }
  }
}

# all nfs tcp allowed to the cluster
resource "oci_core_network_security_group_security_rule" "fss_egress_rule_nfs_tcp" {
  for_each = local.nfs_tcp_ports

  network_security_group_id = oci_core_network_security_group.fss.id
  direction                 = "EGRESS"
  destination               = var.workers_nsg_id
  destination_type          = "NETWORK_SECURITY_GROUP"
  protocol                  = local.tcp

  tcp_options {
    destination_port_range {
      min = each.value
      max = each.value
    }
  }
}

# all nfs udp allowed to the cluster
resource "oci_core_network_security_group_security_rule" "fss_egress_rule_nfs_udp" {
  for_each = local.nfs_tcp_ports

  network_security_group_id = oci_core_network_security_group.fss.id
  direction                 = "EGRESS"
  destination               = var.workers_nsg_id
  destination_type          = "NETWORK_SECURITY_GROUP"
  protocol                  = local.udp

  udp_options {
    destination_port_range {
      min = each.value
      max = each.value
    }
  }
}

resource "oci_file_storage_mount_target" "this" {
  display_name        = "${var.cluster_name}-oke"
  compartment_id      = var.compartment_id
  availability_domain = data.oci_identity_availability_domains.this.availability_domains[0].name
  subnet_id           = var.data_subnet_id
  hostname_label      = "fss1"
  nsg_ids             = [
    oci_core_network_security_group.fss.id
  ]
}

resource "oci_file_storage_export_set" "this" {
  display_name    = "${var.cluster_name}-oke"
  mount_target_id = oci_file_storage_mount_target.this.id
}

resource "kubernetes_storage_class" "oci-fss" {
  metadata {
    name = "oci-fss"
  }

  storage_provisioner = "oracle.com/oci-fss"
  parameters = {
    mntTargetId = oci_file_storage_mount_target.this.id
  }
}
