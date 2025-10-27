# Virtual Machines
resource "azurerm_network_interface" "nic" {
  count               = var.vm_count
  name                = "webapp-nic${count.index + 1}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    Environment = var.environment
  }
}

resource "azurerm_network_interface_backend_address_pool_association" "nic_lb_associate" {
  count                   = var.vm_count
  network_interface_id    = azurerm_network_interface.nic[count.index].id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend_pool.id
}

resource "azurerm_linux_virtual_machine" "vm" {
  count                           = var.vm_count
  name                           = "webapp-vm${count.index + 1}"
  resource_group_name            = azurerm_resource_group.rg.name
  location                       = azurerm_resource_group.rg.location
  size                          = var.vm_size
  admin_username                = var.admin_username
  admin_password                = var.admin_password
  disable_password_authentication = false
  availability_set_id           = azurerm_availability_set.avset.id
  network_interface_ids         = [azurerm_network_interface.nic[count.index].id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  tags = {
    Environment = var.environment
  }
}

# Custom Script Extension
resource "azurerm_virtual_machine_extension" "custom_script" {
  count                = var.vm_count
  name                 = "webapp-script${count.index + 1}"
  virtual_machine_id   = azurerm_linux_virtual_machine.vm[count.index].id
  publisher           = "Microsoft.Azure.Extensions"
  type                = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
    {
        "commandToExecute": "apt-get update && apt-get install -y nginx && wget https://raw.githubusercontent.com/Microsoft/ApplicationInsights-Home/master/Samples/AzureMonitorForLinux/WebServer/node_app/server.js && npm install applicationinsights"
    }
SETTINGS

  tags = {
    Environment = var.environment
  }
}

# Azure Monitor VM Insights
resource "azurerm_virtual_machine_extension" "vm_insights" {
  count                = var.vm_count
  name                 = "vminsights${count.index + 1}"
  virtual_machine_id   = azurerm_linux_virtual_machine.vm[count.index].id
  publisher           = "Microsoft.Azure.Monitor"
  type                = "AzureMonitorLinuxAgent"
  type_handler_version = "1.0"

  tags = {
    Environment = var.environment
  }
}

# Azure SQL Database
resource "azurerm_mssql_server" "sql_server" {
  name                         = "webapp-sqlserver-${random_string.kv_name.result}"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = var.db_admin_login
  administrator_login_password = var.db_admin_password

  public_network_access_enabled = false
  minimum_tls_version          = "1.2"

  tags = {
    Environment = var.environment
  }
}

resource "azurerm_mssql_database" "database" {
  name           = var.db_name
  server_id      = azurerm_mssql_server.sql_server.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "LicenseIncluded"
  max_size_gb    = 2
  sku_name       = "Basic"

  short_term_retention_policy {
    retention_days = 7
  }

  tags = {
    Environment = var.environment
  }
}

# Private Endpoint for SQL Server
resource "azurerm_private_endpoint" "sql_pe" {
  name                = "webapp-sql-pe"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.subnet.id

  private_service_connection {
    name                           = "webapp-sql-privateserviceconnection"
    private_connection_resource_id = azurerm_mssql_server.sql_server.id
    subresource_names             = ["sqlServer"]
    is_manual_connection          = false
  }

  tags = {
    Environment = var.environment
  }
}