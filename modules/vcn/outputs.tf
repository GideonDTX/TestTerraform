output "id" {
  value = oci_core_vcn.this.id
}

output "name" {
  value = oci_core_vcn.this.display_name
}

output "compartment_id" {
  value = var.compartment_id
}

output "vault_id" {
  value = oci_kms_vault.this.id
}

output "kms_key_id" {
  value = oci_kms_key.this.id
}

output "bastion_public_ip" {
  value = var.bastion_enabled ? oci_core_instance.bastion[0].public_ip : ""
}

output "bastion_ssh_private_key" {
  value     = var.bastion_enabled ? tls_private_key.bastion[0].private_key_openssh : ""
  sensitive = true
}

output "bastion_ssh_public_key" {
  value = var.bastion_enabled ? tls_private_key.bastion[0].public_key_openssh : ""
}

output "bastion_nsg_id" {
  value = oci_core_network_security_group.bastion.id
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
