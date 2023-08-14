output "id" {
  value = oci_core_vcn.this.id
}

output "name" {
  value = oci_core_vcn.this.display_name
}

output "compartment_id" {
  value = var.compartment_id
}

output "subnets" {
  value = {
    for name, subnet in oci_core_subnet.this :
      name => {
        id = subnet.id,
        type = subnet.freeform_tags.type
        tier = subnet.freeform_tags.tier
      }
  }
}
