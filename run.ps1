# Copyright (c) Mohamed Hassan. All rights reserved. See License.md in the project root for license information.


Function Print-Request
{
	Write-Output "SIGNPATH_ORGANIZATION_ID: $($env:SIGNPATH_ORGANIZATION_ID)"
	Write-Output "SIGNPATH_SIGNING_REQUESt_ID: $($env:SIGNPATH_SIGNING_REQUEST_ID)"
	Write-Output "SIGNPATH_SIGNING_REQUEST_STATUS: $($env:SIGNPATH_SIGNING_REQUEST_STATUS)"
	Write-Output "APPVEYOR_REPO_TAG_NAME: $($env:APPVEYOR_REPO_TAG_NAME)"
}

Function Download-Artifacts
{
    param ([string]$Output)
    $CI_USER_TOKEN = $env:SIGNPATH_CI_USER_TOKEN
	$SIGNING_REQUEST_ID= $env:SIGNPATH_SIGNING_REQUESt_ID
    $ORGANIZATION_ID = $env:SIGNPATH_ORGANIZATION_ID
	
	$headers = @{
		"Authorization" = "Bearer $($CI_USER_TOKEN)"
	}
	$ProgressPreference = 'SilentlyContinue'   

	Invoke-RestMethod -Uri "https://app.signpath.io/API/v1/$ORGANIZATION_ID/SigningRequests/$SIGNING_REQUEST_ID/SignedArtifact" `
		-Headers $headers `
		-OutFile $Output
	Write-Host "Dwnloading complete"
}

Function unZip 
{
param (
    [string]$Path,
    [string]$Destination  ='./signed'  
)
Expand-Archive -LiteralPath $Path  `
-DestinationPath $Destination -Force

}

function Get-Version 
{    
    param ( [string]$FolderPath)
    $fileName = Get-ChildItem -Path $FolderPath -Filter "*.nupkg" |  Select-Object -First 1     
    write-host $fileName 
   $version = [regex]::Match($fileName, '\d+\.\d+\.\d+(-[\w\d-]+)?').Value
    $isRelease = $version -match '^\d+\.\d+\.\d+$'
    #set environment
    $env:IS_RELEASE='false'
    if ($isRelease -eq $true) {
      $env:IS_RELEASE='true'
    } 
    $env:VERSION= $Version

    return [PSCustomObject]@{
        Version = $version
        IsRelease = $isRelease
    }
}

function Test-Data
{
	# for test only	 
	 $env:SIGNPATH_SIGNING_REQUEST_STATUS = "Completed"
	 $env:SIGNPATH_SIGNING_REQUESt_ID= '0c5459be-aed2-4932-9ceb-ebeb7b8877a6'
	 #$env:VERSION='6.3.0'
}

Function Main 
{
     param ( [string]$FolderPath)
	 #Test-Data
	 
	 if ( $env:SIGNPATH_SIGNING_REQUEST_STATUS -eq "Completed") {
       $env:SIGNING='true'      
      }
      else { 
        Write-Host "Stop execution. SIGNING_REQUEST_STATUS = $($env:SIGNPATH_SIGNING_REQUEST_STATUS)"
		return
      }
	  Print-Request
	  $env:SIGNPATH_SIGNING_REQUESt_ID | Set-Content "sr.txt"
	  $artifact='./artifacts.zip'
      Download-Artifacts $artifact     
	  unZip -Path $artifact
	  Get-ChildItem
	  #$version=Get-Version  './signed'
      $ver=Get-Version  $FolderPath
	  
}