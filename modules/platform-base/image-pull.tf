locals {
  docker_config_json = jsonencode({
    auths = {
      "${var.region}.ocir.io" = {
        username = "{{ .ocir_username }}",
        password = "{{ .auth_token }}",
        email    = "{{ .email }}",
      }
    }
  })
}

resource "kubectl_manifest" "image-pull" {
  depends_on = [
    kubernetes_namespace_v1.this
  ]

  yaml_body = <<-EOT
    apiVersion: external-secrets.io/v1beta1
    kind: ExternalSecret
    metadata:
      name: image-pull
      namespace: ${var.kubernetes_namespace}
    spec:
      refreshInterval: "5m"
      secretStoreRef:
        kind: ClusterSecretStore
        name: oci-vault-${var.cluster_name}
      target:
        name: image-pull
        creationPolicy: Owner
        template:
          type: kubernetes.io/dockerconfigjson
          data:
            .dockerconfigjson: '{"auths":{"${var.region}.ocir.io":{"username":"{{ .ocir_username }}","password":"{{ .auth_token }}", "email": "{{ .email }}","auth":"{{ printf "%s:%s" .ocir_username .auth_token | b64enc }}"}}}'
      dataFrom:
        - extract:
            key: ${var.service_id_secret}
  EOT
}
