data "azurerm_maintenance_configuration" "this" {
  name                = var.update_manager_schedule
  resource_group_name = var.update_manager_rg_name
}