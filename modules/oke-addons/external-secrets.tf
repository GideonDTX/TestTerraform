resource "oci_identity_policy" "external-secrets-read-vault" {
  compartment_id = var.compartment_id
  name           = "${var.cluster_name}-external-secrets-read-vault"
  description    = "allow external secrets to read secret content from vault"

  statements = [
    # dynamic group
    "Allow dynamic-group ${var.cluster_workers_group} to read secret-family in compartment ${var.compartment_name}",
    "Allow dynamic-group ${var.cluster_workers_group} to use key-family in compartment ${var.compartment_name} ",
    # service id for testing
    "Allow group ${local.service_id.group} to read secret-family in compartment ${var.compartment_name}",
    "Allow group ${local.service_id.group} to use key-family in compartment ${var.compartment_name} ",
  ]
}

resource "helm_release" "external-secrets" {
  name       = "external-secrets"
  namespace  = "kube-system"
  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  version    = "0.9.4"
}
