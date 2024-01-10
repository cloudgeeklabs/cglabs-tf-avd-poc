rem Setup User Profile
set LOCALAPPDATA=%USERPROFILE%\AppData\Local

rem Configure Registry to show file extension
reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced /v HideFileExt /t REG_DWORD /d 0 /f

rem Convert bin to ps1 file
copy c:\AzureData\CustomData.bin c:\AzureData\CustomData.ps1

rem Execute the CustomData
set PSExecutionPolicyPreference=Unrestricted
powershell "c:\AzureData\CustomData.ps1" -Argument "c:\AzureData\CustomData_log.txt" 2>&1

rem Extend C: to Max Size
set PSExecutionPolicyPreference=Unrestricted
powershell -command "Resize-Partition -DriveLetter C -Size (Get-PartitionSupportedSize -DriveLetter 'C').SizeMax"

rem Configure WinRM Certificate to be unique for Ansible
set PSExecutionPolicyPreference=Unrestricted
powershell -command "c:/ansible/ConfigureRemotingForAnsible.ps1 -ForceNewSSLCert >> c:\azureData\output_ansible.txt"

rem Install Tanium if it was selected for installation from Packer json
set PSExecutionPolicyPreference=Unrestricted
powershell -command "c:\temp\tanium\install.bat"

rem Install Sophos if it was selected for installation from Packer json
set PSExecutionPolicyPreference=Unrestricted
powershell -command "cmd /c 'C:\temp\SophosSetup.exe --products=all --quiet'"

rem Enable mbadmin local user account - Starting with later builds of Windows 10 Microsoft started disabling all local user accounts. This will reenable mbadmin used during Azure temployment wizard.
net user mbadmin /active:yes