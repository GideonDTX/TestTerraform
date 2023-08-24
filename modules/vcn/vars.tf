variable "compartment_id" {
  description = "The compartment id for all resources"
  type        = string
}

variable "name" {
  description = "The name of the Virtual Cloud Network (VCN)"
  type        = string
}

variable "cidr_block" {
  description = "The CIDR block for the VCN"
  type        = string
}

variable "bastion_enabled" {
  description = "Create a compute instance for bastion access"
  type        = bool
  default     = false
}

variable "bastion_permit_cidr" {
  description = "Allow these CIDRs to access the bastion over ssh"
  type        = map(string)
  default     = {}
}

variable "bastion_image_id" {
  description = "The image id for the bastion host"
  type        = string
  default     = ""
}

variable "subnets" {
  description = "Subnets, route tables, and network security lists (do not include default routes for internet, nat, and services)"
  type        = map(object({
    description = string
    # public or private
    type        = string
    tier        = string
    cidr_block  = string
    dns_label   = string
    route_table_rules = optional(list(object({
      description       = string
      destination       = string
      destination_type  = string
      # only supports OCID of the network entity
      # @todo - if/when DRG is attached add a convention/string to support drg route
      network_entity_id = string
    })), [])
    network_security_list_rules = optional(list(object({
      description = string

      # ingress or egress
      direction   = string
      # if direction is egress, use destination
      destination = optional(string)
      # if direction is ingress, use source
      source = optional(string)

      # "all", ICMP ("1"), TCP ("6"), UDP ("17"), and ICMPv6 ("58")
      protocol = string

      # only required for icmp
      icmp_options = optional(object({
        type = number
        code = optional(number)
      }))

      # only required for tcp
      tcp_options = optional(object({
        min = number
        max = number
      }))

      # only required for udp
      udp_options = optional(object({
        min = number
        max = number
      }))
    })), [])
  }))
}
