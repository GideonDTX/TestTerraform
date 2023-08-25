output "compartment_id" {
  value = var.compartment_id
}

output "compartment_id" {
  value = var.compartment_id
}

output "smpt_user" {
  value = oci_identity_smtp_credential.smtp.username
}

output "smtp_password" {
  value     = oci_identity_smtp_credential.smtp.password
  sensitive = true
}
