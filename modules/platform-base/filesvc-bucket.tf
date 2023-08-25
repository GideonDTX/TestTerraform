locals {
  filesvc_label = "${var.env_name}-filesvc"
}

data "oci_objectstorage_namespace" "filesvc-bucket" {
  compartment_id = var.compartment_id
}

resource "oci_objectstorage_bucket" "filesvc-bucket" {
  compartment_id = var.compartment_id
  name           = local.filesvc_label
  namespace      = data.oci_objectstorage_namespace.filesvc-bucket.namespace

  versioning = "Enabled"
}

resource "oci_identity_policy" "filesvc-bucket" {
  provider = oci.home

  name           = local.filesvc_label
  description    = local.filesvc_label
  compartment_id = var.compartment_id

  statements = [
    "Allow group ${var.service_group} to read objectstorage-namespaces in compartment id ${var.compartment_id}",
    "Allow group ${var.service_group} to manage objectstorage-namespaces in compartment id ${var.compartment_id}",
    "Allow group ${var.service_group} to manage buckets in compartment id ${var.compartment_id} where all { target.bucket.name = '${var.service_group}', request.permission = 'PAR_MANAGE'}",
    "Allow group ${var.service_group} to inspect buckets in compartment id ${var.compartment_id}",
    "Allow group ${var.service_group} to read buckets in compartment id ${var.compartment_id} where target.bucket.name = '${var.service_group}'",
    "Allow group ${var.service_group} to inspect objects in compartment id ${var.compartment_id} where target.bucket.name = '${var.service_group}'",
    "Allow group ${var.service_group} to read objects in compartment id ${var.compartment_id} where target.bucket.name = '${var.service_group}'",
    "Allow group ${var.service_group} to use objects in compartment id ${var.compartment_id} where target.bucket.name = '${var.service_group}'",
    "Allow group ${var.service_group} to manage objects in compartment id ${var.compartment_id} where target.bucket.name = '${var.service_group}'"
  ]
}

# @todo - get the info from ExternalSecret and modify to this format
# resource "kubernetes_secret_v1" "filesvc-bucket" {
#   depends_on = [
#     kubernetes_namespace_v1.this
#   ]

#   metadata {
#     name      = "filesvc-bucket"
#     namespace = var.kubes_namespace
#   }

#   type = "Opaque"
#   data = {
#     OCI_CLI_PROFILE           = "DEFAULT"
#     OCI_CLI_USER              = oci_identity_user.filesvc-bucket.id
#     OCI_CLI_TENANCY           = var.compartment_id
#     OCI_CLI_FINGERPRINT       = oci_identity_api_key.filesvc-bucket.fingerprint
#     OCI_CLI_KEY_FILE_CONTENTS = urlencode(tls_private_key.filesvc-bucket.private_key_pem)
#     OCI_CLI_PASSPHRASE        = ""
#     OCI_CLI_REGION            = var.region
#     OCI_OS_BUCKET             = local.filesvc_label
#     OCI_OS_NAMESPACE          = data.oci_objectstorage_namespace.filesvc-bucket.namespace
#   }
# }