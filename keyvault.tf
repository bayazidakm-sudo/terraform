# Key Vault
resource "azurerm_key_vault" "vault" {
  name                = "webapp-kv-${random_string.suffix.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  soft_delete_retention_days = 7
  purge_protection_enabled   = true

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
    virtual_network_subnet_ids = [azurerm_subnet.subnet.id]
    ip_rules       = var.allowed_ssh_ips
  }

  tags = {
    Environment = var.environment
  }
}

# Key Vault Access Policy for Service Principal
resource "azurerm_key_vault_access_policy" "sp_policy" {
  key_vault_id = azurerm_key_vault.vault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  key_permissions = [
    "Get", "List", "Create", "Delete", "Update",
  ]

  secret_permissions = [
    "Get", "List", "Set", "Delete",
  ]

  certificate_permissions = [
    "Get", "List", "Create", "Delete",
  ]
}

# Store DB Connection String in Key Vault
resource "azurerm_key_vault_secret" "db_connection" {
  name         = "db-connection-string"
  value        = "Server=tcp:${azurerm_mssql_server.sql_server.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.sql_db.name};Persist Security Info=False;User ID=${var.db_admin_username};Password=${var.db_admin_password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
  key_vault_id = azurerm_key_vault.vault.id

  depends_on = [
    azurerm_key_vault_access_policy.sp_policy
  ]
}

# Get current client configuration
data "azurerm_client_config" "current" {}