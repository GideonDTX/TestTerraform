# lookup the service id and put it in a local variable so that it can be used as needed

data "oci_vault_secrets" "service_id" {
  compartment_id = var.compartment_id
  name           = var.service_id_secret
  state          = "ACTIVE"
}

data "oci_secrets_secretbundle" "service_id" {
  secret_id = data.oci_vault_secrets.service_id.secrets[0].id
}

locals {
  service_id = yamldecode(base64decode(data.oci_secrets_secretbundle.service_id.secret_bundle_content[0].content))
}
