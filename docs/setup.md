# Automated Setup with Task
This example automates the design laid out in the [architecture diagram](../.assets/architecture.png). It will produce the following [Sample environment](./docs/example-environment.md)

## Technical Details
* The environment is built using Task.  Task is a powerful automation tool that allows you to automate tasks in a simple and easy way. 
    * To see all subcommands, run `task --list`
* The environment uses Terraform to provision the infrastructure. 
    * The terraform is split up into two components - Core Components and Runners.  
* The `task up` command will a Terraform workspace named after the desired region and provision Azure Automation and Azure Virtual Network.
* The `task packer` command will create a Golden Image for the Hybrid Workers.
* The `task runners -- {{APP_NAME}}` command will create a Terraform workspace named based on the {{APP_NAME}} and the current date.
    * This is how to ensure that the Hybrid Workers are repaved once a week.  
    * A Tag is set on the Azure Resource Group to track the expiration date of the Hybrid Workers.  It defaults to 7 days.
    * A next time the `task runners` command is executed, it will create a new set of Hybrid Workers and destroy the old ones.
    * The task command reads the Azure Automation Account URL from the output of the `task up` command.
* The `task down` command will destroy the Azure Automation, Azure Virutal Machines, and the Azure Virtual Network.
* The runners are Ubuntu Linux with PowerShell installed.
* An SSH key is automatically generated, passed to the runner, and then removed from the Terraform state file to ensure that no human has interative access to the runners. 
* The number of runners created is based on the VM_COUNT variable in the Taskfile.yaml which is passed to the `number_of_runners` variable in the `runners/variables.tf` file.

## Prerequisite 
* A Linux machine or Windows Subsytem for Linux or Docker for Windows 
* Azure Cli and an Azure Subscription
* Terraform 
* [Task](https://taskfile.dev/#/installation)
* Azure subscription with Owner access permissions

## Azure Infrastructure 
```bash
az login
task up -- southcentralus
```

### Example
```bash
$ task up
task: [up] terraform workspace new southcentralus || true
Created and switched to workspace "southcentralus"!

You're now on a new, empty workspace. Workspaces isolate their state,
so if you run "terraform plan" Terraform will not see any existing state
for this configuration.
task: [up] terraform workspace select southcentralus
task: [up] terraform init

Initializing the backend...

Initializing provider plugins...
- Finding latest version of hashicorp/random...
- Finding latest version of hashicorp/http...
...
azurerm_subnet_network_security_group_association.private_endpoints: Creation complete after 8s [id=/subscriptions/ccfc5ddc-43af-4b5e-8cc2-1dda18f2382e/resourceGroups/tomcat-39728_rg/providers/Microsoft.Network/virtualNetworks/tomcat-39728-network/subnets/private-endpoints]
azurerm_subnet_network_security_group_association.servers: Creation complete after 7s [id=/subscriptions/ccfc5ddc-43af-4b5e-8cc2-1dda18f2382e/resourceGroups/tomcat-39728_rg/providers/Microsoft.Network/virtualNetworks/tomcat-39728-network/subnets/servers]

Apply complete! Resources: 13 added, 0 changed, 0 destroyed.

Outputs:

APP_NAME = "tomcat-39728"
AUTOMATION_ACCOUNT_URL = "https://0f0d5b78-6b77-4c0f-977b-a5c08b734704.jrds.scus.azure-automation.net/automationAccounts/0f0d5b78-6b77-4c0f-977b-a5c08b734704"
RESOURCE_GROUP = "tomcat-39728_rg"
```

## Azure Virtual Machines
```bash
az login
task runners -- {APP_NAME} # APP_NAME is the name of the Azure Automation Account from the previous step
```

### Example
```bash 
$ task runners -- tomcat-39728
task: [runners] terraform -chdir=./runners workspace new tomcat-39728-20231227 || true
Created and switched to workspace "tomcat-39728-20231227"!

You're now on a new, empty workspace. Workspaces isolate their state,
so if you run "terraform plan" Terraform will not see any existing state
for this configuration.
task: [runners] terraform -chdir=./runners workspace select tomcat-39728-20231227
task: [runners] terraform -chdir=./runners init

Initializing the backend...

Initializing provider plugins...
...
azurerm_virtual_machine_extension.this[1]: Creation complete after 1m1s [id=/subscriptions/ccfc5ddc-43af-4b5e-8cc2-1dda18f2382e/resourceGroups/tomcat-39728-runners-40370_rg/providers/Microsoft.Compute/virtualMachines/tomcat-39728-40370-worker-231/extensions/hybrid-worker-install]

Apply complete! Resources: 16 added, 0 changed, 0 destroyed.

Outputs:

RESOURCE_GROUP = "tomcat-39728-runners-40370_rg"
task: [runners] terraform -chdir=./runners workspace select tomcat-39728-20231220 || true
Switched to workspace "tomcat-39728-20231220".
task: [runners] terraform -chdir=./runners destroy -auto-approve -var "app_name=tomcat-39728" -var "number_of_runners=2" -var "automation_account_url=https://0f0d5b78-6b77-4c0f-977b-a5c08b734704.jrds.scus.azure-automation.net/automationAccounts/0f0d5b78-6b77-4c0f-977b-a5c08b734704" -compact-warnings || true
random_uuid.id[0]: Refreshing state... [id=408e0cbb-31b4-935e-31cb-bf092db6b098]
....
azurerm_resource_group.this: Still destroying... [id=/subscriptions/ccfc5ddc-43af-4b5e-8cc2-...eGroups/tomcat-39728-runners-54351_rg, 10s elapsed]
azurerm_resource_group.this: Destruction complete after 15s
random_id.this: Destroying... [id=1E8]
random_id.this: Destruction complete after 0s

Destroy complete! Resources: 16 destroyed.
```

## Azure Golden Image
```bash
az login
task packer -- {APP_NAME} # APP_NAME is the name of the Azure Automation Account from the previous step
```

## Destroy Azure Automation Environment
```bash
az login
task down
```

### Example
```bash
$ task down
task: [down] cd ./runners; rm -rf terraform.tfstate.d .terraform.lock.hcl .terraform terraform.tfstate terraform.tfstate.backup .terraform.tfstate.lock.info
task: [down] rm -rf terraform.tfstate.d .terraform.lock.hcl .terraform terraform.tfstate terraform.tfstate.backup .terraform.tfstate.lock.info
task: [down] az group list --tag Application="Hybrid Worker Automation Runners" --query "[].name" -o tsv | xargs -ot -n 1 az group delete -y --verbose -n
az group delete -y --verbose -n tomcat-39728-runners-38214_rg
Command ran in 196.461 seconds (init: 0.204, invoke: 196.256)
task: [down] az group list --tag Application="Hybrid Worker Automation Demo" --query "[].name" -o tsv | xargs -ot -n 1 az group delete -y --verbose -n
az group delete -y --verbose -n tomcat-39728_rg
Command ran in 76.143 seconds (init: 0.118, invoke: 76.026)
```