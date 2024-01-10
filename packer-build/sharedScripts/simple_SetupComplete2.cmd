rem Setup User Profile
set LOCALAPPDATA=%USERPROFILE%\AppData\Local

rem Convert bin to ps1 file
copy c:\AzureData\CustomData.bin c:\AzureData\CustomData.ps1

rem Execute the CustomData
set PSExecutionPolicyPreference=Unrestricted
powershell "c:\AzureData\CustomData.ps1" -Argument "c:\AzureData\CustomData_log.txt" 2>&1

rem Extend C: to Max Size
set PSExecutionPolicyPreference=Unrestricted
powershell -command "Resize-Partition -DriveLetter C -Size (Get-PartitionSupportedSize -DriveLetter 'C').SizeMax"
