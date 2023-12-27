resource "azurerm_automation_runbook" "this" {
  name                    = "print-host-info"
  location                = azurerm_resource_group.this.location
  resource_group_name     = azurerm_resource_group.this.name
  automation_account_name = azurerm_automation_account.this.name
  log_verbose             = "true"
  log_progress            = "true"
  description             = "This is an example runbook that just prints out Host information"
  runbook_type            = "PowerShell"

  content = "[System.Net.Dns]::GetHostName() && [Environment]::GetEnvironmentVariables()"
}