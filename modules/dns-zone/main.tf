terraform {
  required_providers {
    oci = {
      source = "oracle/oci"
    }
  }
}

resource "oci_dns_zone" "this" {
  compartment_id = var.compartment_id
  name           = var.name
  zone_type      = "PRIMARY"
  scope          = var.type == "PRIVATE" ? var.type : null
}

# spf
resource "oci_dns_rrset" "spf" {
  depends_on = [
    oci_dns_zone.this
  ]

  compartment_id  = var.compartment_id

  domain          = var.name
  rtype           = "TXT"
  zone_name_or_id = var.name

  items {
    domain = var.name
    rtype  = "TXT"
    rdata  = "\"v=spf1 include:rp.oracleemaildelivery.com include:ap.rp.oracleemaildelivery.com include:eu.rp.oracleemaildelivery.com ~all\""
    ttl    = 300
  }
}