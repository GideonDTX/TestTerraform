resource "oci_identity_user" "smtp" {
  provider = oci.home

  compartment_id = var.compartment_id
  description    = "smtp-${var.env_name}"
  name           = "smtp-${var.env_name}"
}

resource "oci_identity_group" "smtp" {
  provider = oci.home

  compartment_id = var.compartment_id
  description    = "smtp-${var.env_name}"
  name           = "smtp-${var.env_name}"
}

resource "oci_identity_user_group_membership" "smtp" {
  provider = oci.home

  group_id = oci_identity_group.smtp.id
  user_id  = oci_identity_user.smtp.id
}

resource "oci_identity_policy" "smtp" {
  provider = oci.home

  name           = "smtp-${var.env_name}"
  description    = "allow smtp group permission to send mail"
  compartment_id = var.compartment_id

  depends_on = [
    oci_identity_user_group_membership.smtp
  ]

  statements = [
    "Allow group smtp-${var.env_name} to use approved-senders in compartment id ${var.compartment_id}",
  ]
}

resource "oci_identity_smtp_credential" "smtp" {
  provider = oci.home

  description = "smtp"
  user_id     = oci_identity_user.smtp.id
}

resource "oci_email_sender" "this" {
  count = length(var.approved_senders)

  compartment_id = var.compartment_id
  email_address  = element(var.approved_senders, count.index)
}

resource "kubernetes_secret_v1" "smtp" {
  depends_on = [
    kubernetes_namespace_v1.this
  ]

  metadata {
    name      = "smtp"
    namespace = var.kubes_namespace
  }

  type = "Opaque"
  data = {
    OCI_SMTP_HOST     = "smtp.email.${var.region}.oci.oraclecloud.com"
    OCI_SMTP_PORT     = "587"
    OCI_SMTP_USER     = oci_identity_smtp_credential.smtp.username
    OCI_SMTP_PASSWORD = oci_identity_smtp_credential.smtp.password
    OCI_SMTP_SENDER   = var.approved_senders[0]
  }
}
