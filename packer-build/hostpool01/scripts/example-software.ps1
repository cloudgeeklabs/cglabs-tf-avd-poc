
# Set file and folder path for temp
New-Item -Type Directory c:\temp
$folderpath="c:\temp"


### Example of CLI Install vs Choco\Package Handler
#If SSMS not present, download
$filepath="$folderpath\SSMS-Setup-ENU.exe"
if (!(Test-Path $filepath)){
write-host "Downloading SQL Server SSMS (Latest).."
$URL = "https://aka.ms/ssmsfullsetup"
$clnt = New-Object System.Net.WebClient
$clnt.DownloadFile($url,$filepath)
Write-Host "SSMS installer download complete" -ForegroundColor Green
 
}
else {
 
write-host "Located the SQL SSMS Installer binaries, moving on to install..."
}