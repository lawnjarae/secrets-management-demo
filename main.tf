provider "vault" {
  address = var.vault_address
  token = var.vault_token
}

# locals {
#   # Assuming var.team_namespaces is a map where keys are team names
#   team_users = { for team, _ in var.team_namespaces : "${team}_user" => "${team}_password" }
# }

# Handle HCP's admin namespace
resource "null_resource" "check_admin_namespace" {
  provisioner "local-exec" {
    command = "vault namespace list -format=json | jq -e '.[] | select(. == \"admin/\")' > /dev/null || vault namespace create admin"
    environment = {
      VAULT_ADDR = var.vault_address
      VAULT_TOKEN = var.vault_token
    }
  }

  # triggers = {
  #   always_run = "${timestamp()}"
  # }
}

data "vault_namespace" "admin" {
  depends_on = [null_resource.check_admin_namespace]
  path       = "admin"
}

resource "vault_namespace" "root_namespace" {
  namespace = data.vault_namespace.admin.path
  path      = "secrets_management_demo"
}

resource "vault_mount" "kvv2" {
  namespace   = vault_namespace.root_namespace.path_fq
  path        = "secret"
  type        = "kv-v2"
  description = "KVv2 secrets engine"
}

resource "vault_kv_secret_v2" "important_api_key" {
  mount     = vault_mount.kvv2.path
  namespace = vault_namespace.root_namespace.path_fq
  name      = "secrets-management-demo-shared-secrets"

  data_json = jsonencode({
    api_key     = "api-key-value"
    secret_data = "some-very-secret-data"
  })
}

##### Add in the userpass info for each of the teams #####
resource "vault_auth_backend" "userpass" {
  namespace   = vault_namespace.root_namespace.path_fq
  type        = "userpass"
  description = "Userpass authentication method for teams"
}

##### Add users for each team #####
module "onboard_new_team" {
  source = "./modules/onboard-new-team"

  for_each = var.team_namespaces

  team_name      = each.key
  root_namespace = vault_namespace.root_namespace.path_fq

  depends_on = [vault_auth_backend.userpass]
}

