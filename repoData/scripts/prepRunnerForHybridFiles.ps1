# Set TLS 1.2 as default protocol for Powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Setup Temp Directory
if (Test-Path -Path 'c:\Temp') { 
    set-location 'c:\Temp' 
} else { 
    New-Item -ItemType Directory -Path 'c:\Temp'
    set-location 'c:\Temp'
}

# Download AzFilesHybrid (version 0.2.8) if not exists. 
if (!(Test-Path -Path c:\Temp\AzFilesHybrid.zip)) {
 ## Download AzFilesHybrid
 Invokke-WebRequest -Uri https://github.com/Azure-Samples/azure-files-samples/releases/download/v0.2.8/AzFilesHybrid.zip -OutFile 'c:\Temp\AzFilesHybrid.zip'
} 

# Unzip AzFilesHybrid
Expand-Archive -Path 'c:\Temp\AzFilesHybrid.zip' -DestinationPath 'c:\Temp\AzFilesHybrid'

# Install AzFilesHybrid
Set-Location 'c:\Temp\AzFilesHybrid'
& ./CopyToPSPath.ps1
Import-Module AzFilesHybrid -Force


## Configure Storage Account in AD
# Validate AzFilesHybrid
Import-Module AzFilesHybrid -Force

# Set Subscription of Storage Account
Set-AzContext -Subscription '197f4130-ef26-4439-a354-eb5a2a2d7f85'

# Join Storage Account
Join-AzStorageAccount `
    -ResourceGroupName 'cglabs-avd-eus-poc' `
    -StorageAccountName 'cglabsfslogixeuspoc01' `
    -Domain 'cglabs.work' `
    -DomainAccountType ComputerAccount `
    -OrganizationalUnitName 'HybridStorageAccountJoin' `
    -Confirm:$false

