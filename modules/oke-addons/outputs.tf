output "loadbalancer_ip" {
  value = oci_core_public_ip.ingress-nginx.ip_address
}
