# Azure Web Application Infrastructure

This repository contains Terraform configurations for deploying a highly available and secure web application infrastructure on Azure.

## Architecture Overview

The infrastructure includes:
- Virtual Network with subnet and NSG
- Azure Load Balancer with public IP
- Multiple VMs in an Availability Set
- Azure SQL Database with private endpoint
- Azure Key Vault for secrets management
- Azure Monitor and Application Insights for monitoring
- Microsoft Defender for Cloud for security

## Prerequisites

1. Azure DevOps account with a project created
2. Azure subscription
3. Service Principal with Contributor access
4. Azure Storage Account for Terraform state (pre-configured):
   - Resource Group: webapp-rg1
   - Storage Account: mytfstatefiles1
   - Container: tfstate

## Security Features

1. **Network Security:**
   - NSG with restricted SSH/RDP access
   - Private endpoint for SQL Database
   - TLS 1.2 enforcement for SQL Server

2. **Monitoring & Security:**
   - Azure Monitor VM insights enabled
   - Application Insights with daily data caps
   - Microsoft Defender for Cloud integration
   - Regular security assessments

3. **Access Control:**
   - Key Vault for secret management
   - Restricted admin access
   - Network isolation

## Deployment Guide

1. **Service Connection Setup:**
   - Go to Project Settings > Service Connections
   - Create new Azure Resource Manager connection
   - Name it 'Azure-ServiceConnection'
   - Grant pipeline permissions

2. **Pipeline Variables:**
   Create a variable group 'terraform-vars' with:
   - admin_password
   - db_admin_password
   - trusted_ips (comma-separated list)

3. **Pipeline Setup:**
   - Create new pipeline
   - Select Azure Repos Git
   - Select this repository
   - Pipeline will auto-detect azure-pipelines.yml

## Deployment Validation

1. **Infrastructure Verification:**
   ```powershell
   # Get Load Balancer IP
   $pip = Get-AzPublicIpAddress -ResourceGroupName "webapp-rg"
   $pip.IpAddress

   # Test VM availability
   curl http://$pip.IpAddress
   ```

2. **Database Connectivity:**
   - Use Key Vault to retrieve connection string
   - Test connection using SQL client
   - Verify private endpoint DNS resolution

3. **Monitoring Validation:**
   - Check Azure Monitor for VM metrics
   - Verify Application Insights data flow
   - Review Log Analytics workspace

## Vulnerability Assessment

1. **Initial Scan:**
   - Pipeline includes tfsec security scanning
   - Microsoft Defender for Cloud assessment
   - Network security analysis

2. **Continuous Monitoring:**
   - Daily security assessments
   - Automated vulnerability scanning
   - Compliance monitoring

## Cost Control

1. **Monitoring Costs:**
   - Log Analytics: 30-day retention
   - Application Insights: 5GB daily cap
   - VM insights: Basic tier

2. **Optimization:**
   - Auto-shutdown for dev/test
   - Right-sized VM instances
   - Proper storage tiering

## Emergency Procedures

1. **Security Incident:**
   - Enable JIT VM access
   - Review NSG flow logs
   - Escalate to security team

2. **Service Disruption:**
   - Check Load Balancer health probes
   - Review Application Insights
   - Scale out if needed

## Support and Maintenance

For support:
1. Check Azure Monitor alerts
2. Review Application Insights
3. Analyze Log Analytics queries
4. Contact platform team
