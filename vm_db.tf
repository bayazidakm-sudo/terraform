# Availability Set
resource "azurerm_availability_set" "avset" {
  name                         = "webapp-avset"
  location                     = azurerm_resource_group.rg.location
  resource_group_name          = azurerm_resource_group.rg.name
  platform_fault_domain_count  = 2
  platform_update_domain_count = 5
  managed                      = true

  tags = {
    Environment = var.environment
  }
}

# Network Interface Cards
resource "azurerm_network_interface" "nic" {
  count               = var.vm_count
  name                = "webapp-nic-${count.index + 1}"
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

# Network Interface Backend Pool Association
resource "azurerm_network_interface_backend_address_pool_association" "nic_lb_association" {
  count                   = var.vm_count
  network_interface_id    = azurerm_network_interface.nic[count.index].id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend_pool.id
}

# Virtual Machines
resource "azurerm_linux_virtual_machine" "vm" {
  count                 = var.vm_count
  name                  = "webapp-vm-${count.index + 1}"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  size                  = var.vm_size
  admin_username        = var.admin_username
  admin_password        = var.admin_password
  disable_password_authentication = false
  availability_set_id   = azurerm_availability_set.avset.id
  network_interface_ids = [azurerm_network_interface.nic[count.index].id]

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

# Custom Script Extension for Web Server Installation
resource "azurerm_virtual_machine_extension" "web_server_install" {
  count                = var.vm_count
  name                 = "web-server-install"
  virtual_machine_id   = azurerm_linux_virtual_machine.vm[count.index].id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
    {
        "commandToExecute": "apt-get update && apt-get install -y nginx && systemctl enable nginx && systemctl start nginx"
    }
SETTINGS

  tags = {
    Environment = var.environment
  }
}

# SQL Server
resource "azurerm_mssql_server" "sql_server" {
  name                         = "webapp-sql-${random_string.suffix.result}"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = var.db_admin_username
  administrator_login_password = var.db_admin_password
  minimum_tls_version         = "1.2"

  tags = {
    Environment = var.environment
  }
}

# SQL Database
resource "azurerm_mssql_database" "sql_db" {
  name                = "webapp-db"
  server_id           = azurerm_mssql_server.sql_server.id
  sku_name            = var.db_sku
  max_size_gb         = 2

  tags = {
    Environment = var.environment
  }
}

# SQL Firewall Rules
resource "azurerm_mssql_firewall_rule" "sql_fw_rule" {
  name                = "allow-azure-services"
  server_id           = azurerm_mssql_server.sql_server.id
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

# Random String for unique names
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}
