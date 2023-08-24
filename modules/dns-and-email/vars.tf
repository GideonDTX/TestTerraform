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

variable "allow_users_to_update_records" {
  description = "Users and records map"
  type        = map(list(string))
  default = {}
}

#
# Example:
#
# {
#   "oracleidentitycloudservice/dtxsandbox@neom.com" = [
#     "sandbox",
#     "sandbox-api",
#     "sandbox-id",
#   ]
# }
#