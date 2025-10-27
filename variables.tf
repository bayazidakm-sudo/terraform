variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "webapp-rg"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"
}

variable "environment" {
  description = "Environment name for tagging"
  type        = string
  default     = "production"
}

variable "allowed_ssh_ips" {
  description = "List of IP addresses allowed to SSH"
  type        = list(string)
  default     = []  # Add your trusted IPs here
}

variable "vm_count" {
  description = "Number of VMs to deploy"
  type        = number
  default     = 2
}

variable "vm_size" {
  description = "Size of the VMs"
  type        = string
  default     = "Standard_B2s"
}

variable "admin_username" {
  description = "Admin username for VMs"
  type        = string
  default     = "azureuser"
}

variable "admin_password" {
  description = "Admin password for VMs"
  type        = string
  sensitive   = true
}

variable "db_admin_username" {
  description = "Database admin username"
  type        = string
  default     = "sqladmin"
}

variable "db_admin_password" {
  description = "Database admin password"
  type        = string
  sensitive   = true
}

variable "db_sku" {
  description = "SKU for Azure SQL Database"
  type        = string
  default     = "Basic"
}

variable "enable_monitoring" {
  description = "Enable Azure Monitor and App Insights"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Number of days to retain logs"
  type        = number
  default     = 30
}

variable "daily_log_quota_gb" {
  description = "Daily quota for logs in GB"
  type        = number
  default     = 1
}
