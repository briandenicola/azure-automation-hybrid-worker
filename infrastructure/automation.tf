resource "azurerm_automation_account" "this" {
  name                = local.automation_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku_name            = "Basic"
}

resource "azurerm_automation_hybrid_runbook_worker_group" "this" {
  name                    = local.worker_group_name
  resource_group_name     = azurerm_resource_group.this.name
  automation_account_name = azurerm_automation_account.this.name
}