variable "compartment_id" {
  description = "The compartment id for all resources"
  type        = string
}

variable "repositories" {
  description = "List of repositories and characteristics to take"
  type        = list(object({
    name           = string
    is_public      = optional(bool, false)
    readme_content = optional(string, "# readme")
    readme_format  = optional(string, "text/markdown")
  }))
}
