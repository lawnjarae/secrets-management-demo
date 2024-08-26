provider "vault" {
  address = var.vault_address
}

resource "vault_generic_endpoint" "team_user" {
  namespace = var.namespace
  path      = "auth/userpass/users/${var.team_name}_user"

  data_json = jsonencode({
    password = "${var.team_name}_password"
    policies = ["default"]
  })
}