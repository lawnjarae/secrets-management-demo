
##### Setup team namespeaces ######
resource "vault_namespace" "this" {
  namespace = var.root_namespace
  path      = var.team_name
}

resource "vault_mount" "this" {
  namespace = vault_namespace.this.path_fq
  path      = "secret"
  type      = "kv-v2"
  options = {
    version = "2"
  }
}

##### Add team secrets #####
resource "vault_generic_secret" "this" {
  namespace = vault_namespace.this.path_fq
  path      = "${vault_mount.this.path}/${var.team_name}"
  data_json = jsonencode(
    {
      "ns" = vault_namespace.this.path_fq
    }
  )
}

# Create the policy for the team
resource "vault_policy" "team_policy" {
  name      = "${var.team_name}_policy"
  namespace = var.root_namespace

  policy = <<EOT
# Policy for Dev Team ${var.team_name}
path "${vault_namespace.this.path_fq}/${vault_mount.this.path}/data/*" {
  capabilities = ["read", "list"]
}

path "${vault_namespace.this.path_fq}/${vault_mount.this.path}/metadata/*" {
  capabilities = ["list"]
}

path "${vault_namespace.this.path_fq}/${vault_mount.this.path}/data/${var.team_name}/*" {
  capabilities = ["read", "list", "create", "update", "delete"]
}

path "${vault_namespace.this.path_fq}/${vault_mount.this.path}/metadata/${var.team_name}/*" {
  capabilities = ["list", "delete"]
}

# Allow listing of namespaces within the root namespace
path "sys/namespaces/${vault_namespace.this.path_fq}/*" {
# path "sys/namespaces/*" {
  capabilities = ["list", "read"]
}

# # Allow the user to list the mount points (like secret engines) within their specific namespace
path "sys/mounts/*" {
  capabilities = ["read", "list"]
}

# Tristan files
path "${vault_namespace.this.path_fq}/auth/*" {
  capabilities = ["read", "list", "update", "create"]
}

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
