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
    # On CNAMEs, OCI DNS expects no ending period on the domain record, but oci_email_dkim provides one ...
    domain = replace(oci_email_dkim.this.dns_subdomain_name, "/\\.$/", "")
    rtype  = "CNAME"
    # whereas oci_email_dkim does not provide one here but OCI DNS expects one (the resource creation will
    # succeed with no period but it will register as drift on every subsequent apply)
    rdata  = "${oci_email_dkim.this.cname_record_value}."
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

resource "oci_identity_policy" "this" {
  for_each = var.allow_users_to_update_records

  compartment_id = var.compartment_id

  name           = "dns-update-${each.key}"
  description    = "allow ocidns group to manage ${var.name}"

  statements = concat(
    [
      "Allow group ${each.key} to read dns-zones in compartment ${var.compartment_name}",
      "Allow group ${each.key} to read dns-zones in compartment ${var.compartment_name} where target.dns-zone.name = '${var.name}'"
    ],
    [
      for record in each.value: "Allow group ${each.key} to use dns-records in compartment ${var.compartment_name} where all { target.dns-domain.name = '${record}.${var.name}' }"
    ]
  )
}
