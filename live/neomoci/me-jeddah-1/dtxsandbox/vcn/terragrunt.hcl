locals {
  env_vars     = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  # cidr blocks
  vcn_cidr          = "10.149.96.0/25"
  public1_cidr      = "10.149.96.64/27"
  application1_cidr = "10.149.96.0/26"
  data1_cidr        = "10.149.96.96/27"

  # network labels
  anywhere = "0.0.0.0/0"

  # protocol labels
  icmp     = "1"
  tcp      = "6"
  udp      = "17"

  # icmp labels
  icmp_types = {
    echo_reply    = 0
    dest_unreach  = 3
    source_quench = 4
    echo_request  = 8
    time_exceeded = 11
  }

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

  egress_icmp = [
    {
      description = "Allow outgoing icmp echo-reply from anywhere"
      direction   = "egress"
      destination = local.anywhere
      protocol    = local.icmp
      icmp_options = {
        type = local.icmp_types.echo_reply
      }
    },
    {
      description = "Allow outgoing icmp dest-unreachable from anywhere"
      direction   = "egress"
      destination = local.anywhere
      protocol    = local.icmp
      icmp_options = {
        type = local.icmp_types.dest_unreach
      }
    },
    {
      description = "Allow outgoing icmp source quench from anywhere"
      direction   = "egress"
      destination = local.anywhere
      protocol    = local.icmp
      icmp_options = {
        type = local.icmp_types.source_quench
      }
    },
    {
      description = "Allow outgoing icmp echo-request from anywhere"
      direction   = "egress"
      destination = local.anywhere
      protocol    = local.icmp
      icmp_options = {
        type = local.icmp_types.echo_request
      }
    },
    {
      description = "Allow outgoing icmp time-exceeded from anywhere"
      direction   = "egress"
      destination = local.anywhere
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
  subnets        = {

    public1 = {
      description = "Public subnet for ${local.env_vars.locals.environment}"
      type        = "public"
      tier        = "public"
      cidr_block  = local.public1_cidr
      dns_label   = "pub1"

      network_security_list_rules = concat([
        # ingress rules
        {
          # will be immediately redirected on load balancer to https
          description = "Allow incoming http from anywhere/Internet"
          direction   = "ingress"
          source      = local.anywhere
          protocol    = local.tcp
          tcp_options = {
            min = 80
            max = 80
          }
        },
        {
          # will be directed to load balancer
          description = "Allow incoming https from anywhere/Internet"
          direction   = "ingress"
          source      = local.anywhere
          protocol    = local.tcp
          tcp_options = {
            min = 443
            max = 443
          }
        },
        # egress rules
        {
          # for acccess from load balancer to worker nodes on application subnet
          # https://docs.oracle.com/en-us/iaas/Content/ContEng/Concepts/contengnetworkconfig.htm#securitylistconfig__security_rules_for_load_balancers
          description = "Allow outgoing from load balancer to k8s worker node subnet"
          direction   = "egress"
          destination = local.application1_cidr
          protocol    = local.tcp
          tcp_options = {
            min = 30000
            max = 32767
          }
        },
        {
          # for acccess from load balancer to worker nodes on application subnet to kube-proxy
          # https://docs.oracle.com/en-us/iaas/Content/ContEng/Concepts/contengnetworkconfig.htm#securitylistconfig__security_rules_for_load_balancers
          description = "Allow outgoing from load balancer to k8s worker node subnet to kube-proxy"
          direction   = "egress"
          destination = local.application1_cidr
          protocol    = local.tcp
          tcp_options = {
            min = 10256
            max = 10256
          }
        },
      ],
      local.ingress_icmp, local.egress_icmp)
    }

    application1 = {
      description = "Application/Kubernetes subnet for ${local.env_vars.locals.environment}"
      type        = "private"
      tier        = "app"
      cidr_block  = local.application1_cidr
      dns_label   = "app1"

      network_security_list_rules = concat([
        # ingress rules
        {
          # incoming acccess from load balancer to worker nodes on application subnet
          # https://docs.oracle.com/en-us/iaas/Content/ContEng/Concepts/contengnetworkconfig.htm#securitylistconfig__security_rules_for_load_balancers
          description = "Allow incoming from load balancer to k8s worker node subnet"
          direction   = "ingress"
          source      = local.public1_cidr
          protocol    = local.tcp
          tcp_options = {
            min = 30000
            max = 32767
          }
        },
        {
          # incoming acccess from load balancer to worker nodes on application subnet to kube-proxy
          # https://docs.oracle.com/en-us/iaas/Content/ContEng/Concepts/contengnetworkconfig.htm#securitylistconfig__security_rules_for_load_balancers
          description = "Allow incoming from load balancer to k8s worker node subnet to kube-proxy"
          direction   = "ingress"
          source      = local.public1_cidr
          protocol    = local.tcp
          tcp_options = {
            min = 10256
            max = 10256
          }
        },
        # egress
        {
          # outgoing connections from subnet for DataSource, ObjectModelAPI, and Script Services
          description = "Allow outgoing https to anywhere/Internet"
          direction   = "egress"
          destination = local.anywhere
          protocol    = local.tcp
          tcp_options = {
            min = 443
            max = 443
          }
        },
        {
          # outgoing connections from subnet to data for postgres pgbouncer
          description = "Allow outgoing postgres pgbouncer to data subnet"
          direction   = "egress"
          destination = local.data1_cidr
          protocol    = local.tcp
          tcp_options = {
            min = 6432
            max = 6432
          }
        },
        {
          # outgoing connections from subnet to data for redis
          description = "Allow outgoing redis to data subnet"
          direction   = "egress"
          destination = local.data1_cidr
          protocol    = local.tcp
          tcp_options = {
            min = 6379
            max = 6379
          }
        },
        {
          # outgoing connections from subnet to data for mongodb
          description = "Allow outgoing mongodb to data subnet"
          direction   = "egress"
          destination = local.data1_cidr
          protocol    = local.tcp
          tcp_options = {
            min = 27017
            max = 27017
          }
        },
        {
          # outgoing connections from subnet to data for sunrpc/tcp (for nfs)
          description = "Allow outgoing sunrpc/tcp to data subnet (for nfs)"
          direction   = "egress"
          destination = local.data1_cidr
          protocol    = local.tcp
          tcp_options = {
            min = 111
            max = 111
          }
        },
        {
          # outgoing connections from subnet to data for nfs/tcp
          description = "Allow outgoing nfs/tcp to data subnet"
          direction   = "egress"
          destination = local.data1_cidr
          protocol    = local.tcp
          tcp_options = {
            min = 2048
            max = 2050
          }
        },
        {
          # outgoing connections from subnet to data for sunrpc/udp (for nfs)
          description = "Allow outgoing sunrpc/udp to data subnet (for nfs)"
          direction   = "egress"
          destination = local.data1_cidr
          protocol    = local.udp
          udp_options = {
            min = 111
            max = 111
          }
        },
        {
          # outgoing connections from subnet to data for nfs/udp
          description = "Allow outgoing nfs/udp to data subnet"
          direction   = "egress"
          destination = local.data1_cidr
          protocol    = local.udp
          udp_options = {
            min = 2048
            max = 2048
          }
        },
      ],
      local.ingress_icmp, local.egress_icmp)
    }

    data1 = {
      description = "Database and file subnet for ${local.env_vars.locals.environment}"
      type        = "private"
      tier        = "data"
      cidr_block  = local.data1_cidr
      dns_label   = "data1"

      network_security_list_rules = concat([
        # ingress rules
        {
          # incoming connections from application subnet for postgres pgbouncer
          description = "Allow incoming postgres pgbouncer from application subnet"
          direction   = "ingress"
          source      = local.application1_cidr
          protocol    = local.tcp
          tcp_options = {
            min = 6432
            max = 6432
          }
        },
        {
          # incoming connections from application subnet for redis
          description = "Allow incoming redis from application subnet"
          direction   = "ingress"
          source      = local.application1_cidr
          protocol    = local.tcp
          tcp_options = {
            min = 6379
            max = 6379
          }
        },
        {
          # incoming connections from application subnet for mongodb
          description = "Allow incoming mongodb from application subnet"
          direction   = "ingress"
          source      = local.application1_cidr
          protocol    = local.tcp
          tcp_options = {
            min = 27017
            max = 27017
          }
        },
        {
          # incoming connections from application subnet for sunrpc/tcp (for nfs)
          description = "Allow incoming sunrpc/tcp from application subnet (for nfs)"
          direction   = "ingress"
          source      = local.application1_cidr
          protocol    = local.tcp
          tcp_options = {
            min = 111
            max = 111
          }
        },
        {
          # incoming connections from application subnet for nfs/tcp
          description = "Allow incoming nfs/tcp from application subnet"
          direction   = "ingress"
          source      = local.application1_cidr
          protocol    = local.tcp
          tcp_options = {
            min = 2048
            max = 2050
          }
        },
        {
          # incoming connections from application subnet for sunrpc/udp (for nfs)
          description = "Allow incoming sunrpc/udp from application subnet (for nfs)"
          direction   = "ingress"
          source      = local.application1_cidr
          protocol    = local.udp
          udp_options = {
            min = 111
            max = 111
          }
        },
        {
          # incoming connections from application subnet for nfs/udp
          description = "Allow incoming nfs/udp from application subnet"
          direction   = "ingress"
          source      = local.application1_cidr
          protocol    = local.udp
          udp_options = {
            min = 2048
            max = 2048
          }
        },
        # egress rules
        {
          # this is primarily for ScaleGrid per requirements: https://help.scalegrid.io/docs/prerequisites
          description = "Allow outgoing http to anywhere"
          direction   = "egress"
          destination = local.anywhere
          protocol    = local.tcp
          tcp_options = {
            min = 80
            max = 80
          }
        },
        {
          # this is primarily for ScaleGrid per requirements: https://help.scalegrid.io/docs/prerequisites
          description = "Allow outgoing https to anywhere/Internet"
          direction   = "egress"
          destination = local.anywhere
          protocol    = local.tcp
          tcp_options = {
            min = 443
            max = 443
          }
        },
        {
          # this is primarily for ScaleGrid per requirements: https://help.scalegrid.io/docs/prerequisites
          description = "Allow outgoing amqp to anywhere"
          direction   = "egress"
          destination = local.anywhere
          protocol    = local.tcp
          tcp_options = {
            min = 5671
            max = 5671
          }
        },
      ],
      local.ingress_icmp, local.egress_icmp)
    }
  }
}
