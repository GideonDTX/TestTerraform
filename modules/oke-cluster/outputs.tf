output "id" {
  value = oci_containerengine_cluster.this.id
}

output "name" {
  value = var.name
}

output "compartment_id" {
  value = var.compartment_id
}

output "kubernetes_endpoint" {
  value = oci_containerengine_cluster.this.endpoints[0].private_endpoint
}

output "public_subnet_id" {
  value = var.public_subnet_id
}

output "private_subnet_id" {
  value = var.private_subnet_id
}

output "network_security_groups" {
  value = {
    loadbalancers = {
      id = oci_core_network_security_group.loadbalancers.id
    }
    api           = {
      id = oci_core_network_security_group.api.id
    }
    workers       = {
      id = oci_core_network_security_group.workers.id
    }
  }
}

output "ssh_private_key" {
  value     = tls_private_key.this.private_key_openssh
  sensitive = true
}

output "ssh_public_key" {
  value     = tls_private_key.this.public_key_openssh
}
