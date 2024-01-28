locals {
  filesvc_bucket_name = "${var.kubernetes_namespace}-filesvc"
}
resource "oci_identity_policy" "filesvc-bucket" {
  name           = local.filesvc_bucket_name
  description    = local.filesvc_bucket_name
  compartment_id = var.compartment_id

  statements = [
    "Allow group ${local.service_id.email} to read objectstorage-namespaces in compartment ${var.compartment_name}",
    "Allow group ${local.service_id.email} to manage objectstorage-namespaces in compartment ${var.compartment_name}",
    "Allow group ${local.service_id.email} to manage buckets in compartment ${var.compartment_name} where all { target.bucket.name = '${local.filesvc_bucket_name}', request.permission = 'PAR_MANAGE'}",
    "Allow group ${local.service_id.email} to inspect buckets in compartment ${var.compartment_name}",
    "Allow group ${local.service_id.email} to read buckets in compartment ${var.compartment_name} where target.bucket.name = '${local.filesvc_bucket_name}'",
    "Allow group ${local.service_id.email} to inspect objects in compartment ${var.compartment_name} where target.bucket.name = '${local.filesvc_bucket_name}'",
    "Allow group ${local.service_id.email} to read objects in compartment ${var.compartment_name} where target.bucket.name = '${local.filesvc_bucket_name}'",
    "Allow group ${local.service_id.email} to use objects in compartment ${var.compartment_name} where target.bucket.name = '${local.filesvc_bucket_name}'",
    "Allow group ${local.service_id.email} to manage objects in compartment ${var.compartment_name} where target.bucket.name = '${local.filesvc_bucket_name}'"
  ]
}

resource "oci_objectstorage_bucket" "filesvc-bucket" {
  compartment_id = var.compartment_id
  name           = local.filesvc_bucket_name
  namespace      = data.oci_objectstorage_namespace.this.namespace

  versioning = "Enabled"
}

resource "kubectl_manifest" "external-secret-filesvc-bucket" {
  depends_on = [
    kubernetes_namespace_v1.this
  ]

  yaml_body = <<-EOT
    apiVersion: external-secrets.io/v1beta1
    kind: ExternalSecret
    metadata:
      name: filesvc-bucket
      namespace: ${var.kubernetes_namespace}
    spec:
      refreshInterval: "15m"
      secretStoreRef:
        kind: ClusterSecretStore
        name: oci-vault-${var.cluster_name}
      target:
        name: filesvc-bucket
        creationPolicy: Owner
        template:
          type: Opaque
          data:
            OCI_CLI_PROFILE: "DEFAULT"
            OCI_CLI_USER: "{{ .id }}"
            OCI_CLI_TENANCY: "{{ .tenancy }}"
            OCI_CLI_FINGERPRINT: "{{ .api_signing_key_fingerprint }}"
            OCI_CLI_KEY_FILE_CONTENTS: "{{ .api_signing_key_private_urlencoded }}"
            OCI_CLI_PASSPHRASE: ""
            OCI_CLI_REGION: "${var.region}"
            OCI_OS_BUCKET: "${local.filesvc_bucket_name}"
            OCI_OS_NAMESPACE: "{{ .objectstorage_namespace }}"
      dataFrom:
        - extract:
            key: ${var.service_id_secret}
  EOT
}
