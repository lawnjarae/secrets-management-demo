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
  default = "secrets_management_demo"
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
