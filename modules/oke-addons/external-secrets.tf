resource "oci_identity_policy" "external-secrets-read-vault" {
  compartment_id = var.compartment_id
  name           = "${var.cluster_name}-external-secrets-read-vault"
  description    = "allow external secrets to read secret content from vault"

  statements = [
    # dynamic group
    "Allow dynamic-group ${var.cluster_workers_group} to read secret-family in compartment ${var.compartment_name}",
    "Allow dynamic-group ${var.cluster_workers_group} to use key-family in compartment ${var.compartment_name} ",
    # service id for testing
    "Allow group ${local.service_id.email} to read secret-family in compartment ${var.compartment_name}",
    "Allow group ${local.service_id.email} to use key-family in compartment ${var.compartment_name} ",
  ]
}

resource "helm_release" "external-secrets" {
  name       = "external-secrets"
  namespace  = "kube-system"
  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  version    = "0.9.4"
}

resource "kubectl_manifest" "external-secrets-oci-vault" {
  depends_on = [ 
    oci_identity_policy.external-secrets-read-vault
  ]

  yaml_body = <<-EOT
    apiVersion: external-secrets.io/v1beta1
    kind: ClusterSecretStore
    metadata:
      name: oci-vault-${var.cluster_name}
    spec:
      provider:
        oracle:
          vault: ${var.vault_id}
          region: ${var.region}
  EOT
}
