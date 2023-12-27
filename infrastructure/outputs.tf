output "RESOURCE_GROUP" {
    value = azurerm_resource_group.this.name
    sensitive = false
}

output "APP_NAME" {
    value = local.resource_name
    sensitive = false
}

output "AUTOMATION_ACCOUNT_URL" {
    value = azurerm_automation_account.this.hybrid_service_url
    sensitive = false
}