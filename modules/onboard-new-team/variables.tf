variable "vault_address" {
  type        = string
  default     = null
  description = "The address of your Vault cluster."
}

variable "team_name" {
  type        = string
  description = "The name of the team for which to create the userpass user."
}

variable "root_namespace" {
  type        = string
  description = "The namespace where the userpass auth is located."
  default     = "admin/secrets_management_demo"
}

variable "needs_shared_secrets" {
  type        = bool
  description = "Does this user need access to shared secrets?"
  default     = false
}