data "azurerm_automation_account" "this" {
  name                = local.automation_name
  resource_group_name = data.azurerm_resource_group.automation_rg.name
}