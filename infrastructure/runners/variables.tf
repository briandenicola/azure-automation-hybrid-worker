variable "app_name" {
  description = "The Azure Automation Account Name"
  type        = string
}

variable "vm_sku" {
  default     = "Standard_B1s"
  type        = string
  description = "The Sku for the Azure Virtual Machine"
}

variable "number_of_runners" {
  default     = 1
  type        = number
  description = "value for the number of runners to deploy"
}

variable "automation_account_url" {
  type        = string
  description = "The URL for the Azure Automation Account"
}

variable "update_manager_schedule" {
  type        = string
  description = "The schedule for the update manager"
  default     = "standard"
}

variable "update_manager_rg_name" {
  type        = string
  description = "The resource group name for the update manager"
  default     = "Core_Monitor_RG"
}