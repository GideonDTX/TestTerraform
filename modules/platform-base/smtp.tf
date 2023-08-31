resource "kubectl_manifest" "external-secret-smtp" {
  depends_on = [
    kubernetes_namespace_v1.this
  ]

  yaml_body = <<-EOT
    apiVersion: external-secrets.io/v1beta1
    kind: ExternalSecret
    metadata:
      name: smtp
      namespace: ${var.kubernetes_namespace}
    spec:
      refreshInterval: "15m"
      secretStoreRef:
        kind: ClusterSecretStore
        name: oci-vault-${var.cluster_name}
      target:
        name: smtp
        creationPolicy: Owner
        template:
          type: Opaque
          data:
            OCI_SMTP_HOST: "smtp.email.${var.region}.oci.oraclecloud.com"
            OCI_SMTP_PORT: "587"
            OCI_SMTP_USER: "{{ .smtp_username }}"
            OCI_SMTP_PASSWORD: "{{ .smtp_password }}"
            OCI_SMTP_SENDER: "${var.approved_senders[0]}"
      dataFrom:
        - extract:
            key: ${var.service_id_secret}
  EOT
}
