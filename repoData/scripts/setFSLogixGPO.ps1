# Execute on Domain Controller or Where you confugre GPO 
$url = "https://aka.ms/fslogix_download"
$destination = "c:\temp\fslogix.zip"
New-Item -Path "c:\" -Name "Temp" -ItemType "directory" -ErrorAction SilentlyContinue
Import-Module BitsTransfer
Start-BitsTransfer -Source $url -Destination $destination -Priority High
Expand-Archive -LiteralPath $destination -DestinationPath c:\temp\fslogix
Copy-Item -Path "C:\temp\fslogix\fslogix.admx" -Destination "C:\Windows\PolicyDefinitions\"
Copy-Item -Path "C:\temp\fslogix\fslogix.adml" -Destination "C:\Windows\PolicyDefinitions\en-US\"