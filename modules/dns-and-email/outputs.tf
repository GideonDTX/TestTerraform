output "id" {
  value = oci_dns_zone.this.id
}

output "name" {
  value = oci_dns_zone.this.name
}

output "nameservers" {
  value = [
    for obj in oci_dns_zone.this.nameservers: obj.hostname
  ]
}
