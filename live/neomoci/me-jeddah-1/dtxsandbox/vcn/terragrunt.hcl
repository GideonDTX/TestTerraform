locals {
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  env_vars    = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  # cidr blocks
  vcn_cidr          = "10.2.0.0/16" # Adjusted CIDR for the entire VCN
  public1_cidr      = "10.2.1.0/24" # Adjusted CIDR for public1 subnet
  application1_cidr = "10.2.2.0/24" # Adjusted CIDR for application1 subnet
  data1_cidr        = "10.2.3.0/24" # Adjusted CIDR for data1 subnet

  # enable bastion only when needed (for emergencies, vpn outages, etc.)
  bastion_enabled = false
  bastion_permit_cidr = {
    # Example:
    # Harlan_Barnes = "73.7.139.22/32"
  }
  bastion_private_ports = {
    # Example:
    # kubernetes_api = 6443
  }
  # Oracle Automous Linux 8.8
  bastion_image_id = "ocid1.image.oc1.me-jeddah-1.aaaaaaaaueynum7iew5v7huc5ji6fgjmpi2tugcrlgcnrdrzqtwwwwy2b25a"
  bastion_public = [
    for name, cidr in local.bastion_permit_cidr : {
      description = "Allow incoming ssh from ${name}"
      direction   = "ingress"
      source      = cidr
      protocol    = local.tcp
      tcp_options = {
        min = 22
        max = 22
      }
    }
  ]
  bastion_private = [
    for name, port in local.bastion_private_ports : {
      description = "Allow incoming ${name} from public subnet for bastion"
      direction   = "ingress"
      source      = local.public1_cidr
      protocol    = local.tcp
      tcp_options = {
        min = port
        max = port
      }
    }
  ]

  # network labels
  anywhere = "0.0.0.0/0"

  # protocol labels
  icmp     = "1"
  tcp      = "6"
  udp      = "17"
  anyproto = "all"

  # icmp labels
  icmp_types = {
    echo_reply    = 0
    dest_unreach  = 3
    source_quench = 4
    echo_request  = 8
    time_exceeded = 11
  }

  # these repeat in lots of places so we set these as local variables
  ingress_icmp = [
    {
      description = "Allow incoming icmp echo-reply from anywhere"
      direction   = "ingress"
      source      = local.anywhere
      protocol    = local.icmp
      icmp_options = {
        type = local.icmp_types.echo_reply
      }
    },
    {
      description = "Allow incoming icmp dest-unreachable from anywhere"
      direction   = "ingress"
      source      = local.anywhere
      protocol    = local.icmp
      icmp_options = {
        type = local.icmp_types.dest_unreach
      }
    },
    {
      description = "Allow incoming icmp source quench from anywhere"
      direction   = "ingress"
      source      = local.anywhere
      protocol    = local.icmp
      icmp_options = {
        type = local.icmp_types.source_quench
      }
    },
    {
      description = "Allow incoming icmp echo-request from anywhere"
      direction   = "ingress"
      source      = local.anywhere
      protocol    = local.icmp
      icmp_options = {
        type = local.icmp_types.echo_request
      }
    },
    {
      description = "Allow incoming icmp time-exceeded from anywhere"
      direction   = "ingress"
      source      = local.anywhere
      protocol    = local.icmp
      icmp_options = {
        type = local.icmp_types.time_exceeded
      }
    },
  ]
}

terraform {
  source = "${get_parent_terragrunt_dir()}/../modules//vcn"
}

include "root" {
  path = find_in_parent_folders()
}

inputs = {
  compartment_id = local.env_vars.locals.compartment_id
  name           = local.env_vars.locals.environment
  cidr_block     = local.vcn_cidr

  bastion_enabled     = local.bastion_enabled
  bastion_permit_cidr = local.bastion_permit_cidr
  bastion_image_id    = local.bastion_image_id

  subnets         = {
    public1 = {
      description = "Public subnet for ${local.env_vars.locals.environment}"
      type        = "public"
      tier        = "public"
      cidr_block  = local.public1_cidr
      dns_label   = "pub1"

      route_table_rules = [
        {
          description       = "Public subnets default route to internet gateway"
          destination       = "0.0.0.0/0"
          destination_type  = "CIDR_BLOCK"
          network_entity_id = "INTERNET_GATEWAY"
        }
      ]
    }

    application1 = {
      description = "Application/Kubernetes subnet for ${local.env_vars.locals.environment}"
      type        = "private"
      tier        = "app"
      cidr_block  = local.application1_cidr
      dns_label   = "app1"

      route_table_rules = [
        {
          description       = "Private subnets default route to NAT gateway"
          destination       = "0.0.0.0/0"
          destination_type  = "CIDR_BLOCK"
          network_entity_id = "NAT_GATEWAY"
       }
      ]
    }

    data1 = {
      description = "Database and file subnet for ${local.env_vars.locals.environment}"
      type        = "private"
      tier        = "data"
      cidr_block  = local.data1_cidr
      dns_label   = "data1"

      route_table_rules = [
        {
          description       = "Private subnets default route to NAT gateway"
          destination       = "0.0.0.0/0"
          destination_type  = "CIDR_BLOCK"
          network_entity_id = "NAT_GATEWAY"
        }
     ]
    }
  
  }
}

