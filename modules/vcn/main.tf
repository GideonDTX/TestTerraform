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
  # networks
  anywhere = "0.0.0.0/0"
}

# data sources
data "oci_core_services" "this" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}

## core

# VCN
resource "oci_core_vcn" "this" {
  compartment_id = var.compartment_id
  cidr_block     = var.cidr_block
  display_name   = var.name
  dns_label      = var.name
}

## gateways

# internet
resource "oci_core_internet_gateway" "this" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "internet gateway for ${var.name}"
}

# nat
resource "oci_core_public_ip" "nat" {
  compartment_id = var.compartment_id
  lifetime       = "RESERVED"
}

resource "oci_core_nat_gateway" "this" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "nat gateway for ${var.name}"
  public_ip_id   = oci_core_public_ip.nat.id
}

# service
resource "oci_core_service_gateway" "this" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "service gateway for ${var.name}"

  services {
    service_id = data.oci_core_services.this.services[0]["id"]
  }
}

## Security for Default Resources

# default security lists are used when none other are chosen, lock them down in case of use
resource "oci_core_default_security_list" "this" {
  manage_default_resource_id = oci_core_vcn.this.default_security_list_id
}

## Subnets

resource "oci_core_subnet" "this" {
  for_each = var.subnets

  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id

  dns_label      = each.value.dns_label
  cidr_block     = each.value.cidr_block
  display_name   = each.value.description

  prohibit_public_ip_on_vnic = each.value.type == "public" ? true : false

  route_table_id    = oci_core_route_table.this[each.key].id
  security_list_ids = [oci_core_security_list.this[each.key].id]

  freeform_tags = {
    name = each.key
    type = each.value.type
    tier = each.value.tier
  }
}

## Route Tables

# route table and rules
resource "oci_core_route_table" "this" {
  for_each = var.subnets

  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "Route table for ${each.key}"

  # default route rule for public subnets to the internet gateway
  dynamic "route_rules" {
    for_each = each.value.type == "public" ? [1] : []

    content {
      description       = "Public subnets default route to internet gateway"
      destination       = local.anywhere
      network_entity_id = oci_core_internet_gateway.this.id
    }
  }

  # default route rule for private subnets to the nat gateway
  dynamic "route_rules" {
    for_each = each.value.type == "private" ? [1] : []

    content {
      description       = "Private subnets default route to NAT gateway"
      destination       = local.anywhere
      network_entity_id = oci_core_nat_gateway.this.id
    }
  }

  # Oracle service rule for private subnets to the service gateway (not allowed to on public subnets)
  dynamic "route_rules" {
    for_each = each.value.type == "private" ? [1] : []

    content {
      description       = "All subnets route Oracle services through service gateway"
      destination       = data.oci_core_services.this.services[0]["cidr_block"]
      destination_type  = "SERVICE_CIDR_BLOCK"
      network_entity_id = oci_core_service_gateway.this.id
    }
  }

  dynamic "route_rules" {
    for_each = { for index, obj in each.value.route_table_rules : index => obj }

    content {
      description       = each.value.description
      destination       = each.value.destination
      destination_type  = each.value.destination_type
      network_entity_id = each.value.network_entity_id
    }
  }
}

## Network Security Lists

resource "oci_core_security_list" "this" {
  for_each = var.subnets

  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "Network security list for ${each.key}"

  dynamic "egress_security_rules" {
    for_each = {
      for index, obj in each.value.network_security_list_rules : index => obj if obj.direction == "egress"
     }

    content {
      description = egress_security_rules.value.description
      destination = egress_security_rules.value.destination
      protocol    = egress_security_rules.value.protocol

      dynamic "icmp_options" {
        for_each = egress_security_rules.value.icmp_options == null ? [] : [egress_security_rules.value.icmp_options]

        content {
          type = icmp_options.value.type
          code = icmp_options.value.code
        }
      }

      dynamic "tcp_options" {
        for_each = egress_security_rules.value.tcp_options == null ? [] : [egress_security_rules.value.tcp_options]

        content {
          min = tcp_options.value.min
          max = tcp_options.value.max
        }
      }

      dynamic "udp_options" {
        for_each = egress_security_rules.value.udp_options == null ? [] : [egress_security_rules.value.udp_options]

        content {
          min = udp_options.value.min
          max = udp_options.value.max
        }
      }
    }
  }

  dynamic "ingress_security_rules" {
    for_each = {
      for index, obj in each.value.network_security_list_rules : index => obj if obj.direction == "ingress"
     }

    content {
      description = ingress_security_rules.value.description
      source      = ingress_security_rules.value.source
      protocol    = ingress_security_rules.value.protocol

      dynamic "icmp_options" {
        for_each = ingress_security_rules.value.icmp_options == null ? [] : [ingress_security_rules.value.icmp_options]

        content {
          type = icmp_options.value.type
          code = icmp_options.value.code
        }
      }

      dynamic "tcp_options" {
        for_each = ingress_security_rules.value.tcp_options == null ? [] : [ingress_security_rules.value.tcp_options]

        content {
          min = tcp_options.value.min
          max = tcp_options.value.max
        }
      }

      dynamic "udp_options" {
        for_each = ingress_security_rules.value.udp_options == null ? [] : [ingress_security_rules.value.udp_options]

        content {
          min = udp_options.value.min
          max = udp_options.value.max
        }
      }
    }
  }
}
