# Azure Provider configuration
provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
      recover_soft_deleted_key_vaults = true
    }
  }
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  
  tags = {
    Environment = var.environment
    Managed_By  = "Terraform"
  }
}

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "webapp-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = {
    Environment = var.environment
  }
}

# Subnet
resource "azurerm_subnet" "subnet" {
  name                 = "webapp-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]

  service_endpoints = ["Microsoft.Sql", "Microsoft.KeyVault"]
}

# Network Security Group
resource "azurerm_network_security_group" "nsg" {
  name                = "webapp-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "allow-http"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                  = "Tcp"
    source_port_range         = "*"
    destination_port_range    = "80"
    source_address_prefix     = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-ssh"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                  = "Tcp"
    source_port_range         = "*"
    destination_port_range    = "22"
    source_address_prefixes   = var.allowed_ssh_ips
    destination_address_prefix = "*"
  }

  tags = {
    Environment = var.environment
  }
}

# Subnet NSG Association
resource "azurerm_subnet_network_security_group_association" "subnet_nsg" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# Public IP for Load Balancer
resource "azurerm_public_ip" "pip" {
  name                = "webapp-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                = "Standard"

  tags = {
    Environment = var.environment
  }
}

# Load Balancer
resource "azurerm_lb" "lb" {
  name                = "webapp-lb"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                = "Standard"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.pip.id
  }

  tags = {
    Environment = var.environment
  }
}

# Backend Address Pool
resource "azurerm_lb_backend_address_pool" "backend_pool" {
  name            = "webapp-backend-pool"
  loadbalancer_id = azurerm_lb.lb.id
}

# Load Balancer Health Probe
resource "azurerm_lb_probe" "probe" {
  name                = "webapp-probe"
  loadbalancer_id     = azurerm_lb.lb.id
  protocol            = "Http"
  port                = 80
  request_path        = "/"
  interval_in_seconds = 15
  number_of_probes    = 2
}

# Load Balancer Rule
resource "azurerm_lb_rule" "rule" {
  name                           = "webapp-rule"
  loadbalancer_id               = azurerm_lb.lb.id
  protocol                      = "Tcp"
  frontend_port                 = 80
  backend_port                  = 80
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_ids      = [azurerm_lb_backend_address_pool.backend_pool.id]
  probe_id                      = azurerm_lb_probe.probe.id
}

# Application Insights
resource "azurerm_application_insights" "appinsights" {
  name                = "webapp-insights"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "web"
  retention_in_days   = 90
  daily_data_cap_in_gb = 1

  tags = {
    Environment = var.environment
  }
}
