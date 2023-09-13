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
  compartment_id = var.compartment_id

  name           = "dns-and-email-update-${replace(var.name, "/\\./", "-dot-")}"
  description    = "allow groups to manage ${var.name}"

  statements = flatten(concat(
    [
      for obj in var.groups_allowed_to_update_dns: [
        "Allow ${obj.type} ${obj.name} to read dns-zones in compartment ${var.compartment_name}",
        "Allow ${obj.type} ${obj.name} to use dns-zones in compartment ${var.compartment_name} where target.dns-zone.name = '${var.name}'",
        "Allow ${obj.type} ${obj.name} to use dns-records in compartment ${var.compartment_name} where target.dns-zone.name = '${var.name}'",
      ]
    ],
  ))
}
