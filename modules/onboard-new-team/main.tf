
##### Setup team namespeaces ######
# resource "vault_namespace" "this" {
#   namespace = var.root_namespace
#   path      = var.team_name
# }

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

# path "${var.root_namespace}/${vault_mount.this.path}/data/*" {
#   capabilities = ["create", "read", "update", "delete", "list"]
# }

# path "${var.root_namespace}/${vault_mount.this.path}/metadata/*" {
#   capabilities = ["read", "list"]
# }

# # Enable and manage secrets engines
# path "${var.root_namespace}/sys/mounts/*" {
#    capabilities = ["create", "read", "update", "delete", "list"]
# }

# # List available secrets engines
# path "${var.root_namespace}/sys/mounts" {
#   capabilities = [ "read" ]
# }

# Allow listing of namespaces within the root namespace
# path "sys/namespaces/${var.root_namespace}/*" {
# # path "sys/namespaces/*" {
#   capabilities = ["list", "read"]
# }
# path "${var.root_namespace}/${vault_mount.this.path}/data/${var.team_name}/*" {
#   capabilities = ["read", "list", "create", "update", "delete"]
# }

# path "${var.root_namespace}/${vault_mount.this.path}/metadata/${var.team_name}/*" {
#   capabilities = ["list", "delete"]
# }
# Tristan files
# path "${var.root_namespace}/auth/*" {
#   capabilities = ["read", "list", "update", "create"]
# }

EOT
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
