resource "azurerm_network_interface" "this" {
  count               = var.number_of_runners
  name                = "${local.vm_name}-${substr(random_uuid.id[count.index].result, 0, 3)}-nic"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  ip_configuration {
    name                          = local.vm_name
    subnet_id                     = data.azurerm_subnet.servers.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "this" {
  count                                                  = var.number_of_runners
  name                                                   = "${local.vm_name}-${substr(random_uuid.id[count.index].result, 0, 3)}"
  location                                               = azurerm_resource_group.this.location
  resource_group_name                                    = azurerm_resource_group.this.name
  admin_username                                         = "manager"
  size                                                   = var.vm_sku
  patch_assessment_mode                                  = "AutomaticByPlatform"
  patch_mode                                             = "AutomaticByPlatform" 
  provision_vm_agent                                     = true
  bypass_platform_safety_checks_on_user_schedule_enabled = true

  network_interface_ids = [
    azurerm_network_interface.this[count.index].id,
  ]

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.this.id]
  }

  admin_ssh_key {
    username   = "manager"
    public_key = tls_private_key.rsa.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    name                 = "${local.vm_name}-${substr(random_uuid.id[count.index].result, 0, 3)}-osdisk"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  # Extension not supported on Mariner yet.
  # source_image_reference {
  #    publisher = "MicrosoftCBLMariner"
  #    offer     = "cbl-mariner"
  #    sku       = "cbl-mariner-2-gen2"
  #    version   = "latest"
  # }

  # Install PowerShell 7.4.0
  custom_data = local.install_script
}

resource "azurerm_maintenance_assignment_virtual_machine" "this" {
  count                        = var.number_of_runners
  location                     = azurerm_resource_group.this.location
  maintenance_configuration_id = data.azurerm_maintenance_configuration.this.id
  virtual_machine_id           = azurerm_linux_virtual_machine.this[count.index].id
}

resource "azurerm_virtual_machine_extension" "this" {
  count                      = var.number_of_runners
  name                       = "hybrid-worker-install"
  virtual_machine_id         = azurerm_linux_virtual_machine.this[count.index].id
  publisher                  = "Microsoft.Azure.Automation.HybridWorker"
  type                       = "HybridWorkerForLinux"
  type_handler_version       = "1.1"
  automatic_upgrade_enabled  = true
  auto_upgrade_minor_version = true

  settings = <<SETTINGS
    {
        "AutomationAccountURL": "${var.automation_account_url}"
    }
SETTINGS

  #
  # If using an HTTP proxy, add the following to the settings block above:
  #   protected_settings = <<PROTECTED_SETTINGS
  #     {
  #        "Proxy_URL": "http://${var.proxy_ip_address}"
  #     }
  # PROTECTED_SETTINGS
  #
}

resource "azurerm_automation_hybrid_runbook_worker" "this" {
  count                   = var.number_of_runners
  resource_group_name     = data.azurerm_resource_group.automation_rg.name
  automation_account_name = data.azurerm_automation_account.this.name
  worker_group_name       = local.worker_group_name
  vm_resource_id          = azurerm_linux_virtual_machine.this[count.index].id
  worker_id               = random_uuid.id[count.index].result
}
