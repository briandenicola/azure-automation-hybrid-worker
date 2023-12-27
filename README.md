# Azure Automation Hybrid Worker Demo 

## Overview 
Azure Automation is a service that allows you to automate tasks in Azure. Azure Automation allows you to run runbooks in the cloud or on-premises. It is a standard command-and-control architecture, where the Azure Automation service sends jobs to workers. The workers performs the jobs.  Sometimes these jobs require access to Azure resources that are not accessible from the public internet. In this case, you can use a Hybrid Worker. 

A Hybrid Worker is a virtual machine that is deployed in your Azure subscription. The Hybrid Worker is registered with the Azure Automation service. 

This demo shows how to deploy a disposalable Hybrid Workers using Terraform and Packer without any interaction with the actual virtual machines.  All software is installed via [Cloud Init](./infrastructure/runners/cloud-init.txt) and the Hybrid Workers are registered with the Azure Automation service using the Azure Automation VM Extension.  The machines are also registered with Azure Update Manager for patching.  

The machines are assigned an Identity and a role assignment is created to allow the Hybrid Worker to access Azure resources. The machines are given unique id and are deployed in a separate resource group based on another random id.

The Hybrid Workers are intended to be repaved once a week. This demo does so by having Task create a Terraform workspace based on today's date. When executed, Task will create new machiens for the Hybrid Worker Group then clean up any hybrid workers from the previous week.

Since a Hybrid Worker needs to have many depedencies installed, it is best to create a Golden Image. This demo can Packer to create a Golden Image and have it published into an Azure Shared Image Gallery

## Components
Component | Usage
------ | ------
Azure Automation | Automation Account for Runbooks 
Azure Virtual Machine | Hybrid Workers
Azure Virtual Network | Virtual Network for Hybrid Workers

## Architecture
![Architecture](.assets/architecture.png)

## Prerequisite 
* A Linux machine or Windows Subsytem for Linux or Docker for Windows 
* Azure Cli and an Azure Subscription
* Terraform 
* [Task](https://taskfile.dev/#/installation)
* Azure subscription with Owner access permissions

# Setup
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

## Deploy Azure Automation Environment
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

# Validate

## Portal
* Login in to the Azure Portal and navigate to the Azure Automation Account
* Click on the **Runbooks** blade and click on the **Test Pane** for the **print-host-info** runbook
* Select **Hybrid Workers**. Click on **Start**. Wait for the runbook to complete
* Click on the **Output** tab to see the output of the runbook. Validate that it ran on one of the Hybrid Workers

## Azure Cli
```bash
$ az extension add --name automation
$ az vm list -o table
Name                           ResourceGroup                  Location        Zones
-----------------------------  -----------------------------  --------------  -------
tomcat-39728-38214-worker-04b  TOMCAT-39728-RUNNERS-38214_RG  southcentralus
tomcat-39728-38214-worker-a22  TOMCAT-39728-RUNNERS-38214_RG  southcentralus

$ az automation account list -g tomcat-39728_rg -o table
CreationTime                      DisableLocalAuth    LastModifiedTime                  Location        Name                     PublicNetworkAccess    ResourceGroup    State
--------------------------------  ------------------  --------------------------------  --------------  -----------------------  ---------------------  ---------------  -------
2023-12-27T18:28:47.483000+00:00  False               2023-12-27T18:28:47.483000+00:00  southcentralus  tomcat-39728-automation  True                   tomcat-39728_rg  Ok

$ az automation hrwg list  --automation-account-name tomcat-39728-automation -g tomcat-39728_rg -o table
GroupType    Name                             ResourceGroup
-----------  -------------------------------  ---------------
User         tomcat-39728-automation-workers  tomcat-39728_rg

$ az automation runbook start  --automation-account-name tomcat-39728-automation -g tomcat-39728_rg -n print-host-info --run-on tomcat-39728-automation-workers
{
  "creationTime": "2023-12-27T18:46:45.037000+00:00",
  "endTime": null,
  "exception": null,
  "id": "/subscriptions/ccfc5ddc-43af-4b5e-8cc2-1dda18f2382e/resourceGroups/tomcat-39728_rg/providers/Microsoft.Automation/automationAccounts/tomcat-39728-automation/jobs/7167118b-e8e2-4f94-9d0b-9334d2435319",
  "jobId": "aa9cae18-32c2-4127-82b9-d507e5501923",
  "lastModifiedTime": "2023-12-27T18:46:45.037000+00:00",
  "lastStatusModifiedTime": "2023-12-27T18:46:45.037000+00:00",
  "name": "7167118b-e8e2-4f94-9d0b-9334d2435319",
  "parameters": {},
  "provisioningState": "Processing",
  "resourceGroup": "tomcat-39728_rg",
  "runOn": "tomcat-39728-automation-workers",
  "runbook": {
    "name": "print-host-info"
  },
  "startTime": null,
  "startedBy": null,
  "status": "New",
  "statusDetails": "None",
  "type": "Microsoft.Automation/AutomationAccounts/Jobs"
}

$ az automation job show  --automation-account-name tomcat-39728-automation -g tomcat-39728_rg -n aa9cae18-32c2-4127-82b9-d507e5501923
Command group 'automation job' is experimental and under development. Reference and support levels: https://aka.ms/CLI_refstatus
{
  "creationTime": "2023-12-27T18:46:45.079375+00:00",
  "endTime": "2023-12-27T18:47:11.748434+00:00",
  "exception": null,
  "id": "/subscriptions/ccfc5ddc-43af-4b5e-8cc2-1dda18f2382e/resourceGroups/tomcat-39728_rg/providers/Microsoft.Automation/automationAccounts/tomcat-39728-automation/jobs/aa9cae18-32c2-4127-82b9-d507e5501923",
  "jobId": "aa9cae18-32c2-4127-82b9-d507e5501923",
  "lastModifiedTime": "2023-12-27T18:47:11.748434+00:00",
  "lastStatusModifiedTime": "2023-12-27T18:47:11.748434+00:00",
  "name": "7167118b-e8e2-4f94-9d0b-9334d2435319",
  "parameters": {},
  "provisioningState": "Succeeded",
  "resourceGroup": "tomcat-39728_rg",
  "runOn": "tomcat-39728-automation-workers",
  "runbook": {
    "name": "print-host-info"
  },
  "startTime": "2023-12-27T18:47:08.244576+00:00",
  "startedBy": "{scrubbed}",
  "status": "Completed",
  "statusDetails": "None",
  "type": "Microsoft.Automation/AutomationAccounts/Jobs"
}
```
