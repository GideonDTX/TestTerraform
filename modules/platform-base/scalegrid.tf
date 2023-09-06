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

# # this is not supported by cloud services
# resource "oci_identity_policy" "scalegrid-root-policy" {
#   compartment_id = var.compartment_id
#   name           = "${local.service_id.group}-root-policy"
#   description    = "for ScaleGrid user profile ${var.cluster_name}"

#   statements = [
#     "Allow group ${local.service_id.group} to inspect compartments in tenancy",
#     "Allow group ${local.service_id.group} to use tag-namespaces in tenancy"
#   ]
# }

resource "oci_identity_policy" "scalegrid-compartment-policy" {
  compartment_id = var.compartment_id
  name           = "${local.service_id.group}-compartment-policy"
  description    = "for ScaleGrid user profile ${var.cluster_name}"

  statements = [
    "Allow group ${local.service_id.group} to inspect vcns in compartment ${var.compartment_name}",
    "Allow group ${local.service_id.group} to inspect route-tables in compartment ${var.compartment_name}",
    "Allow group ${local.service_id.group} to read instance-images in compartment ${var.compartment_name}",
    "Allow group ${local.service_id.group} to read app-catalog-listing in compartment ${var.compartment_name}",
    "Allow group ${local.service_id.group} to use vnics in compartment ${var.compartment_name}",
    "Allow group ${local.service_id.group} to use vnic-attachments in compartment ${var.compartment_name}",
    "Allow group ${local.service_id.group} to use subnets in compartment ${var.compartment_name}",
    "Allow group ${local.service_id.group} to manage volume-attachments in compartment ${var.compartment_name}",
    "Allow group ${local.service_id.group} to use volumes in compartment ${var.compartment_name} where target.resource.tag.ScaleGrid.DBProvider = 'ScaleGrid'",
    "Allow group ${local.service_id.group} to inspect volumes in compartment ${var.compartment_name}",
    "Allow group ${local.service_id.group} to manage volumes in compartment ${var.compartment_name} where request.operation = 'CreateVolume'",
    "Allow group ${local.service_id.group} to manage volumes in compartment ${var.compartment_name} where  target.resource.tag.ScaleGrid.DBProvider = 'ScaleGrid'",
    "Allow group ${local.service_id.group} to manage volume-backups in compartment ${var.compartment_name} where request.operation = 'CreateVolumeBackup'",
    "Allow group ${local.service_id.group} to manage volume-backups in compartment ${var.compartment_name} where target.resource.tag.ScaleGrid.DBProvider = 'ScaleGrid'",
    "Allow group ${local.service_id.group} to read volume-backups in compartment ${var.compartment_name}",
    "Allow group ${local.service_id.group} to manage instances in compartment ${var.compartment_name} where ANY { request.operation = 'LaunchInstance', request.permission = 'INSTANCE_UPDATE', target.resource.tag.ScaleGrid.DBProvider = 'ScaleGrid'}",
    "Allow group ${local.service_id.group} to inspect instances in compartment ${var.compartment_name}",
    "Allow group ${local.service_id.group} to use network-security-groups in compartment ${var.compartment_name}",
    "Allow group ${local.service_id.group} to manage network-security-groups in compartment ${var.compartment_name} where request.operation = 'AddNetworkSecurityGroupSecurityRules'",
  ]
}

resource "oci_core_network_security_group" "scalegrid-postgresql" {
  for_each = data.oci_identity_availability_domain.this

  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "${local.service_id.group}-AD${each.value.ad_number}-postgresql"
}

resource "oci_core_network_security_group" "scalegrid-redis" {
  for_each = data.oci_identity_availability_domain.this

  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "${local.service_id.group}-AD${each.value.ad_number}-redis"
}

resource "oci_core_network_security_group" "scalegrid-mongodb" {
  for_each = data.oci_identity_availability_domain.this

  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "${local.service_id.group}-AD${each.value.ad_number}-mongodb"
}
