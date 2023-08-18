terraform {
  required_providers {
    oci = {
      source = "oracle/oci"
    }
  }
}

# dns zone
resource "oci_dns_zone" "this" {
  compartment_id = var.compartment_id
  name           = var.name
  zone_type      = "PRIMARY"
  scope          = var.type == "PRIVATE" ? var.type : null
}

# email domain
resource "oci_email_email_domain" "this" {
  compartment_id = var.compartment_id
  name           = var.name
}

# email dkim
resource "oci_email_dkim" "this" {
  name            = var.name
  email_domain_id = oci_email_email_domain.this.id
}

# dkim cname
resource "oci_dns_rrset" "dkim" {
  depends_on = [
    oci_dns_zone.this
  ]

  compartment_id  = var.compartment_id

  domain          = oci_email_dkim.this.dns_subdomain_name
  rtype           = "CNAME"
  zone_name_or_id = var.name

  items {
    domain = oci_email_dkim.this.dns_subdomain_name
    rtype  = "CNAME"
    rdata  = oci_email_dkim.this.cname_record_value
    ttl    = 300
  }
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