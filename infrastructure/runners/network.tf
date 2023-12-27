data "azurerm_virtual_network" "this" {
  name                = "${local.resource_name}-network"
  resource_group_name = data.azurerm_resource_group.automation_rg.name
}

data "azurerm_subnet" "servers" {
  name                 = "servers"
  resource_group_name  = data.azurerm_resource_group.automation_rg.name
  virtual_network_name = data.azurerm_virtual_network.this.name
}