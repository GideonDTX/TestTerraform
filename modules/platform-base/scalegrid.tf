# locals
locals {
    availability_domains = [
    for ad in data.oci_identity_availability_domains.this.availability_domains :
      ad.id
  ]
}

# lookup ads
data "oci_identity_availability_domain" "this" {
  for_each = toset(local.availability_domains)

  compartment_id = var.compartment_id
  id             = each.key
}

resource "oci_identity_tag_namespace" "scalegrid" {
  compartment_id = var.compartment_id

  # note, tag namespaces are global
  name        = "${var.compartment_name}_ScaleGrid"
  description = "Tags for ScaleGrid in ${var.compartment_name}"
  is_retired  = false
}

resource "oci_identity_tag" "scalegrid-dbprovider" {
  tag_namespace_id = oci_identity_tag_namespace.scalegrid.id

  name        = "DBProvider"
  description = "For ScaleGrid"
  is_retired  = false
}

resource "oci_identity_policy" "scalegrid-compartment-policy" {
  compartment_id = var.compartment_id
  name           = "${local.service_id.group}-compartment-policy"
  description    = "For ScaleGrid user profile ${var.cluster_name}"

  statements = [
    "Allow group ${local.service_id.group} to inspect vcns in compartment ${var.compartment_name}",
    "Allow group ${local.service_id.group} to inspect route-tables in compartment ${var.compartment_name}",
    "Allow group ${local.service_id.group} to read instance-images in compartment ${var.compartment_name}",
    "Allow group ${local.service_id.group} to read app-catalog-listing in compartment ${var.compartment_name}",
    "Allow group ${local.service_id.group} to use vnics in compartment ${var.compartment_name}",
    "Allow group ${local.service_id.group} to use vnic-attachments in compartment ${var.compartment_name}",
    "Allow group ${local.service_id.group} to use subnets in compartment ${var.compartment_name}",
    "Allow group ${local.service_id.group} to manage volume-attachments in compartment ${var.compartment_name}",
    "Allow group ${local.service_id.group} to use volumes in compartment ${var.compartment_name} where target.resource.tag.${oci_identity_tag_namespace.scalegrid.name}.DBProvider = 'ScaleGrid'",
    "Allow group ${local.service_id.group} to inspect volumes in compartment ${var.compartment_name}",
    "Allow group ${local.service_id.group} to manage volumes in compartment ${var.compartment_name} where request.operation = 'CreateVolume'",
    "Allow group ${local.service_id.group} to manage volumes in compartment ${var.compartment_name} where  target.resource.tag.${oci_identity_tag_namespace.scalegrid.name}.DBProvider = 'ScaleGrid'",
    "Allow group ${local.service_id.group} to manage volume-backups in compartment ${var.compartment_name} where request.operation = 'CreateVolumeBackup'",
    "Allow group ${local.service_id.group} to manage volume-backups in compartment ${var.compartment_name} where target.resource.tag.${oci_identity_tag_namespace.scalegrid.name}.DBProvider = 'ScaleGrid'",
    "Allow group ${local.service_id.group} to read volume-backups in compartment ${var.compartment_name}",
    "Allow group ${local.service_id.group} to manage instances in compartment ${var.compartment_name} where ANY { request.operation = 'LaunchInstance', request.permission = 'INSTANCE_UPDATE', target.resource.tag.${oci_identity_tag_namespace.scalegrid.name}.DBProvider = 'ScaleGrid'}",
    "Allow group ${local.service_id.group} to inspect instances in compartment ${var.compartment_name}",
    "Allow group ${local.service_id.group} to use network-security-groups in compartment ${var.compartment_name}",
    "Allow group ${local.service_id.group} to manage network-security-groups in compartment ${var.compartment_name} where request.operation = 'AddNetworkSecurityGroupSecurityRules'",
    "Allow group ${local.service_id.group} to inspect all-resources in compartment ${var.compartment_name}",
    "Allow group ${local.service_id.group} to use tag-namespaces in compartment ${var.compartment_name}",
  ]
}

resource "oci_core_network_security_group" "scalegrid-postgresql" {
  for_each = data.oci_identity_availability_domain.this

  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "${var.cluster_name}-AD${each.value.ad_number}-postgresql"
}

resource "oci_core_network_security_group" "scalegrid-redis" {
  for_each = data.oci_identity_availability_domain.this

  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "${var.cluster_name}-AD${each.value.ad_number}-redis"
}

resource "oci_core_network_security_group" "scalegrid-mongodb" {
  for_each = data.oci_identity_availability_domain.this

  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "${var.cluster_name}-AD${each.value.ad_number}-mongodb"
}
