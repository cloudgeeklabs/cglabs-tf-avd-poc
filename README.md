# Deploy AVD via IaC #

## Notes ##

Verify VNET/Hosts has access to the following endpoints. <https://learn.microsoft.com/en-us/azure/virtual-desktop/safe-url-list?tabs=azure#session-host-virtual-machines>. Eventually I will include the Networking components as part of PoC.. But for now..

## Resource Organization ##

The structure of your resource storage directly determines your options for implementing resource management and governance.

- Subscriptions
- Reesource Groups
- Landing Zones (collection of Subscriptions under a common MG)

### Things to Consider ###

- Number of Virtual Machines that will be required. 
- Refrain from deploying more than 5000 VMs in a single Region and Subscription. If you require more desktops, then span multiple Subscriptions in the same Region. 
- Resources and Regions should align. Keep things in the same Region
  - Metadata (ARM/API Deployment)
  - AVD Resources: Host Pools, Applications Groups, and Workspaces stay in region with Hosts and Network
  - Session Hosts (VMs) bound to Region with vNET
  - vNets are bound to a specific Region
  - Storage (goes without saying doesn't it) especially if you are using Private Endpoints!
  
Resources like Keyvault, Compute Gallery, Images, etc. Do not need to follow the Region. Just be sure to configure the Compute Gallery to replicate the Image to each target region (configured via IaC\Packer)

### Naming and Tagging ###

A standardized naming convention is your starting point for organizing cloud-hosted resources. Properly structured naming systems allow rapid resource identification for both management and accounting purposes. If you follow existing IT naming conventions in other parts of your organization, consider whether to align your cloud naming conventions with them or make your cloud naming conventions unique and separate.

### MGs and Subs ###

Group resources logically in management groups so you can target policy and initiative assignments with Azure Policy.

Create management groups under your root-level management group to represent the types of workloads (archetypes) you host, and management groups based on their security, compliance, connectivity, and feature needs. If you use this grouping structure, you can apply a set of Azure policies at the management group level for all workloads that require the same security, compliance, connectivity, and feature settings.

Subscriptions serve as a scale unit so component workloads can scale within your platform subscription limits. Remember to consider subscription resource limits during your workload design sessions.

Subscriptions provide a management boundary for governance and isolation, which clearly separates concerns. The following diagrams show the structure and Resource Groups we recommend you create and use as administrative domains and lifecycle purposes for each Azure Region you deploy. 

Example:

- Azure Virtual Desktop Service Objects:  Create a Resource Group for Azure Virtual Desktop Service Objects from Host Pool VMs.  Service objects like Workspaces, Host Pools and Application Groups.  
  - Networking:  Generally created as part of the Cloud Adoption Framework Landing zone
  - Storage:  If not already created as part of Cloud Adoption Framework, create a resource group for storage accounts
  - Session hosts compute: Create a Resource Group for Virtual Machines, Disks and Network Interfaces. These have a different life cycle than the Azure Virtual Desktop Service Objects.
  - Shared Resources:  Create a Resource Group for shared resources like custom VM images, this encourages self-service so you could have a subscription for each business line, for instance.

- Management Group (LandingZone for AVD)
  - Subscription (AVD-Shared-Resources)
    - rg-Region-avd-shared-resources
  - Subscription (Networking for AVD) | Regional Specific Resources but not Workload Specific
    - Likely already exists or was deployed via the LandingZone Vending Template
    - rg-region-avd-network
  - Subscription (AVD WorkLoad) | Regional and Workload Specific Resource
    - rg-region-avd-workload-service-objects
    - rg-region-avd-workload-pool-compute
    - rg-region-avd-workload-storage

## Deploy AVD Shared Resources ##

First thing we want to do is deploy the required infrastructure four our deployment. This will deploy components like: Azure AppReg for Packer (Service Principal), Azure Compute Gallery, Azure Image Definition (for Packer), Azure Storage Account for Artifacts (as needed), Azure KeyVault (secrets & keys), and Log Analytics Workspace.

Step 1: Connect to Azure and Set Target Subscription (AVD LandingZone) and create EnvVars for TF AppReg for local deployment.

```powershell
# 1. Auth to Azure and Set Context
[void](Connect-AzLogin)
$azContext = (Set-AzContext -Subscription <<Replace SubscriptionName or Id>>)

# 2. Create SP/App Registration
$sp = New-AzADServicePrincipal -DisplayName cglabs-tf-app -Role "Contributor"

# 3. Set TF EnvVars
$ENV:ARM_CLIENT_ID = ($sp.AppId)
$ENV:ARM_CLIENT_SECRET = (ConvertTo-SecureString ($sp.PasswordCredentials.SecretText) -AsPlainText -Force)
$ENV:ARM_TENANT_ID = $azContext.Tenant.Id
$ENV:ARM_SUBSCRIPTION_ID = $azContext.Subscription.Id

# 4. Initialize Terraform - this pulls down and providers and dependencies to a local .terraform folder (this should be in .gitignore!)
terraform -chdir='.\infra-as-code\deployments\cglabs-avd-eus-sharedsvcs' init

# 5. Create Plan file and validate everything looks right
terraform -chdir='.\infra-as-code\deployments\cglabs-avd-eus-sharedsvcs' plan -out main.tfplan

# 6. Apply the Plan and deploy Infra. 
terraform -chdir='.\infra-as-code\deployments\cglabs-avd-eus-sharedsvcs' apply main.tfplan
```

## Configure/Deploy Packer Image to ACG ##

NOTE: You'll need to assign any RBAC Permissions to KeyVault for the the TF AppReg (and other groups that may need to manage secrets)

```powershell
# 7. Load the Statefile Outputs and Add Packer AppReg from KeyVault 
$stateOutputs = ((gc .\infra-as-code\modules\prereqs\terraform.tfstate | convertFrom-Json).outputs)
$ENV:ARM_CLIENT_ID = (Get-AzKeyVaultSecret -VaultName ($stateOutputs.KeyVaultName.value) -SecretName 'cglabs-packer-app-ClientId' -AsPlainText)
$ENV:ARM_CLIENT_SECRET = (Get-AzKeyVaultSecret -VaultName ($stateOutputs.KeyVaultName.value) -SecretName 'cglabs-packer-app-ClientSecret' -AsPlainText)
$ENV:ARM_TENANT_ID = $azContext.Tenant.Id
$ENV:ARM_SUBSCRIPTION_ID = $azContext.Subscription.Id

# 8. Search for the desired Sku we want to deploy.
## Windows 11 Skus
Get-AzVmImageSku -Location 'East US' -PublisherName 'MicrosoftWindowsDesktop' -Offer 'Windows-11'
## Windows 10 Skus
Get-AzVmImageSku -Location 'East US' -PublisherName 'MicrosoftWindowsDesktop' -Offer 'Windows-10'

# 9. Deploy Image via Packer into our Azure Compute Gallery
## Update Packer Vars (./packer-build/hostpool01/vars.pkrvars.hcl)
image_version   = "2023.1024.01"
image_name      = "cglabs-hostpool01" 
gallery_name    = "cglabsavdeusacg"
acgResGroup     = "cglabs-avd-eus-sharedsvcs"
subscription_id = "197f4130-ef26-4439-a354-eb5a2a2d7f85"

## Initialize Packer Directory
packer init ./packer-build/hostpool01/hostpool01.pkr.hcl

## Build Image | -force is being used to force cleam up of our previous image. 
packer build -force -var-file="./packer-build/hostpool01/vars.pkrvars.hcl" ./packer-build/hostpool01/hostpool01.pkr.hcl
```

## Deploy AVD Resources ##

```powershell
# 10. Initialized Terraform Directory/Modules
terraform -chdir='.\infra-as-code\cglabs-avd-eus-avd' init

# 11. Terraform Plan for AVD
terraform -chdir='.\infra-as-code\cglabs-avd-eus-avd' plan -out main.tfplan

# 12. Terraform Apply for AVD
terraform -chdir='.\infra-as-code\cglabs-avd-eus-avd' apply main.tfplan
```

## Deploy VMs and Add to HostPool ##

```powershell
# 13. Initialized Terraform Directory/Modules
terraform -chdir='.\infra-as-code\cglabs-avd-eus-poc' init

# 14. Terraform Plan for AVD
terraform -chdir='.\infra-as-code\cglabs-avd-eus-poc' plan -out main.tfplan

# 15. Terraform Apply for AVD
terraform -chdir='.\infra-as-code\cglabs-avd-eus-poc' apply main.tfplan

```
