variable "name" {
  description = "zone name"
  type        = string
}

variable "type" {
  description = "zone type"
  type        = string
  default     = "PUBLIC"
}

variable "compartment_id" {
  description = "The compartment id for the zone"
  type        = string
}

variable "compartment_name" {
  description = "The compartment name for the zone"
  type        = string
}

variable "groups_allowed_to_update_dns" {
  description = "Group permissions"
  type        = list(object({
    name    = string
    type    = string
  }))
  default = []
}
