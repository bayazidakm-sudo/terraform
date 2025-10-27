variable "resource_group_name" {
  description = "Name of the resource group"
  default     = "webapp-rg"
}

variable "location" {
  description = "Azure region"
  default     = "eastus"
}

variable "vm_count" {
  description = "Number of VMs to create"
  default     = 2
}

variable "vm_size" {
  description = "Size of the VMs"
  default     = "Standard_B2s"
}

variable "admin_username" {
  description = "Admin username for VMs"
  default     = "webadmin"
}

variable "admin_password" {
  description = "Admin password for VMs"
  sensitive   = true
}

variable "trusted_ips" {
  description = "List of trusted IP addresses for SSH/RDP access"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Replace with actual trusted IPs
}

variable "db_name" {
  description = "Name of the Azure SQL Database"
  default     = "webapp-db"
}

variable "db_admin_login" {
  description = "Database administrator login"
  default     = "sqladmin"
}

variable "db_admin_password" {
  description = "Database administrator password"
  sensitive   = true
}

variable "environment" {
  description = "Environment name for tagging"
  default     = "production"
}

variable "log_retention_days" {
  description = "Number of days to retain logs"
  default     = 30
}

variable "daily_quota_gb" {
  description = "Daily data volume quota for Application Insights in GB"
  default     = 5
}