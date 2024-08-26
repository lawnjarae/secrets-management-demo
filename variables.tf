variable "vault_address" {
  type        = string
  default     = null
  description = "The address of your Vault cluster."
}

variable "vault_token" {
  type = string
  default = null
}

variable "default_team_namespace" {
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