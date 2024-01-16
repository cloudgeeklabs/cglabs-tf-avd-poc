## Install FSLogix Apps
$shortURL = "https://aka.ms/fslogix/download"

## Convert ShortURL to latest Version FullURL
$request = [System.Net.WebRequest]::create($shortURL)
$response = $request.GetResponse()
$fullURL = $response.ResponseUri.AbsoluteUri
$response.Close()

## Create Temp Folder
if (!(test-path c:\temp)) {
    New-Item -ItemType Directory -Path c:\temp
}

## Download FSLogix Zip
Invoke-WebRequest -Uri $fullURL -OutFile ('c:\temp\' + $fullURL.split('/')[-1])

## Extract files from ZIP
Expand-Archive -Path ('c:\temp\' + $fullURL.split('/')[-1]) -DestinationPath 'c:\temp\fslogix\'

if (test-path 'C:\temp\fslogix\x64\Release\FSLogixAppsSetup.exe') {
    # Run installer
    Start-Process 'C:\temp\fslogix\x64\Release\FSLogixAppsSetup.exe' -wait -ArgumentList "/install /quiet /norestart"
}