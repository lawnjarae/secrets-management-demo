variable "vault_address" {
  type        = string
  default     = null
  description = "The address of your Vault cluster."
}

variable "vault_token" {
  type    = string
  default = null
}

variable "demo_root_namespace" {
  default = "dev_team_a"
}

variable "team_namespaces" {
  type = set(string)
  default = [
    "dev_team_a",
    "dev_team_b",
    "dev_team_c",
  ]
}

variable "team_mounts" {
  type = list(object({
    team_name                   = string
    add_to_shared_secrets_group = bool
  }))
  default = [
    {
      team_name                   = "dev_team_a"
      add_to_shared_secrets_group = true
    },
    {
      team_name                   = "dev_team_b"
      add_to_shared_secrets_group = true
    },
    {
      team_name                   = "dev_team_c"
      add_to_shared_secrets_group = false
    }
  ]
}
