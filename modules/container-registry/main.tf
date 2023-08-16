terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
    }
  }
}

locals {}

resource "oci_artifacts_container_repository" "this" {
  for_each = {
    for o in var.repositories : o.name => o
  }

  compartment_id = var.compartment_id
  display_name   = each.value.name

  is_public    = each.value.is_public

  #
  # Note: Currently, you aren't allowed to set "isImmutable=true" via the API
  #
  # │ Error: 400-BAD_REQUEST, Setting isImmutable is not currently supported
  # │ Suggestion: Please retry or contact support for help with service: Artifacts Container Repository
  # │ Documentation: https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/artifacts_container_repository 
  # │ API Reference: https://docs.oracle.com/iaas/api/#/en/registry/20160918/ContainerRepository/CreateContainerRepository 
  # │ Request Target: POST https://artifacts.me-jeddah-1.oci.oraclecloud.com/20160918/container/repositories 
  # │ Provider version: 5.9.0, released on 2023-08-17.  
  # │ Service: Artifacts Container Repository 
  # │ Operation Name: CreateContainerRepository 
  # │ OPC request ID: 9a622d2da185a85bd434f8fb69b32893/244705fffc4ba84b50bf123c 
  #
  is_immutable = false


  readme {
    content = each.value.readme_content
    format  = each.value.readme_format
  }
}
