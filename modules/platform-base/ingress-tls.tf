resource "kubectl_manifest" "ingress-tls" {
  depends_on = [
    kubernetes_namespace_v1.this
  ]

  for_each = var.dns_names

  validate_schema = false

  yaml_body = <<-YAML
    apiVersion: cert-manager.io/v1
    kind: Certificate
    metadata:
      name: ${each.key}-tls
      namespace: ${var.kubernetes_namespace}
    spec:
      secretName: ${each.key}-tls
      issuerRef: 
        kind: ClusterIssuer
        name: letsencrypt-prod
      dnsNames:
        - ${each.value}
  YAML
}
