variable "compartment_id" {
  description = "The compartment id"
  type        = string
}

variable "compartment_name" {
  description = "The compartment name"
  type        = string
}

variable "env_name" {
  description = "The environment name"
  type        = string
}

variable "access_groups" {
  description = "Provide readonly or readwrite access to these groups"
  type        = object({
    readonly  = optional(list(string), [])
    readwrite = optional(list(string), [])
  })
  default = {
    readonly  = []
    readwrite = []
  }
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
