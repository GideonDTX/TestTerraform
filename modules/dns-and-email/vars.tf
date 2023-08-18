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
