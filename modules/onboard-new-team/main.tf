# Get a few data resources so we can create groups and entity ids
data "vault_identity_group" "shared_secrets_group" {
  namespace  = var.root_namespace
  group_name = "shared_secrets_group"
}

data "vault_auth_backend" "userpass" {
  namespace = var.root_namespace
  path      = "userpass"
}

resource "vault_mount" "this" {
  namespace = var.root_namespace
  path      = "kvv2_${var.team_name}"
  type      = "kv-v2"
  options = {
    version = "2"
  }
}

resource "random_pet" "secret_name" {
  count     = 3
  length    = 2
  separator = "_"
}

# Generate 9 random pet names for secret values
resource "random_pet" "secret_value" {
  count     = 9
  length    = 3
  separator = "_"
}

# Create 3 secrets, each with 3 different versions
resource "vault_generic_secret" "this" {
  count     = 9 # 3 versions for each of the 3 secrets
  namespace = var.root_namespace
  path      = "${vault_mount.this.path}/${random_pet.secret_name[count.index % 3].id}"

  data_json = jsonencode(
    {
      "pet" = random_pet.secret_value[count.index].id
    }
  )
}

# Create the policy for the team
resource "vault_policy" "team_policy" {
  name      = "${var.team_name}_policy"
  namespace = var.root_namespace

  policy = <<EOT
# Policy for Dev Team ${var.team_name}
path "${vault_mount.this.path}/data/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "${vault_mount.this.path}/metadata/*" {
  capabilities = ["read", "list"]
}

# Allow the user to list the mount points (like secret engines) within their specific namespace
path "sys/mounts/*" {
   capabilities = ["create", "read", "update", "delete", "list"]
}
path "sys/mounts" {
  capabilities = ["read", "list"]
}

path "sys/namespaces/*" {
  capabilities = ["list"]
}
EOT
}

# Create the entity
# Create the user
# Create the alias
# Add the entity_id to the group list
resource "vault_identity_entity" "this" {
  namespace = var.root_namespace
  name      = var.team_name
  metadata = {
    "team" = var.team_name
  }
}

# Create the Userpass user for the team
resource "vault_generic_endpoint" "team_user" {
  namespace = var.root_namespace
  path      = "auth/userpass/users/${var.team_name}"
  # path      = "auth/userpass/users/${var.team_name}_user"

  data_json = jsonencode({
    password = "${var.team_name}"
    # password = "${var.team_name}_password"
    policies = [vault_policy.team_policy.name]
  })

  depends_on = [vault_policy.team_policy]
}

resource "vault_identity_entity_alias" "this" {
  namespace      = var.root_namespace
  name           = var.team_name
  mount_accessor = data.vault_auth_backend.userpass.accessor
  canonical_id   = vault_identity_entity.this.id
}

resource "vault_identity_group_member_entity_ids" "group_entity_ids" {
  count     = var.needs_shared_secrets ? 1 : 0
  namespace = var.root_namespace
  group_id  = data.vault_identity_group.shared_secrets_group.id
  exclusive = false

  # Append the new entity ID to the existing list
  member_entity_ids = [vault_identity_entity.this.id]
}
