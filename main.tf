provider "vault" {
  address = var.vault_address
  token   = var.vault_token
}

provider "random" {

}

resource "vault_namespace" "root_namespace" {
  path      = "${var.demo_root_namespace}"
}

resource "vault_mount" "kvv2" {
  namespace   = vault_namespace.root_namespace.path_fq
  path        = "shared_secrets"
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

# Shared secrets policy
resource "vault_policy" "shared_secrets_policy" {
  name      = "shared_secrets_policy"
  namespace = vault_namespace.root_namespace.path_fq

  policy = <<EOT
# Policy to access shared secrets
path "${vault_mount.kvv2.path}/data/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "${vault_mount.kvv2.path}/metadata/*" {
  capabilities = ["read", "list"]
}
EOT
}

# Shared secrets group
resource "vault_identity_group" "shared_secrets_group" {
  name      = "shared_secrets_group"
  namespace = vault_namespace.root_namespace.path_fq

  member_entity_ids = []

  policies = [
    vault_policy.shared_secrets_policy.name
  ]
}

##### Add users for each team #####
module "onboard_new_team" {
  source = "./modules/onboard-new-team"

  for_each = {
    for team in var.team_mounts :
    team.team_name => team
  }

  team_name            = each.value.team_name
  root_namespace       = vault_namespace.root_namespace.path_fq
  needs_shared_secrets = each.value.add_to_shared_secrets_group

  depends_on = [vault_auth_backend.userpass, vault_identity_group.shared_secrets_group]
}

