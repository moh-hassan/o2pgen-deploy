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
	Write-Host "Dwnloading complete, path: $Output"
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

# set environment variables env:SignVersion
function Get-Version 
{    
    param ( [string]$FolderPath)
    $fileName = Get-ChildItem -Path $FolderPath -Filter "*.nupkg" |  Select-Object -First 1     
    write-host $fileName 
   $version = [regex]::Match($fileName, '\d+\.\d+\.\d+(-[\w\d-]+)?').Value
   $version = "v" + $version
    $isRelease = $version -match '^\d+\.\d+\.\d+$'
    #set environment
    $env:IS_RELEASE='false'
    if ($isRelease -eq $true) {
      $env:IS_RELEASE='true'
    } 
    $env:SignVersion= $Version
    write-host "Package Version: $Version"

    return [PSCustomObject]@{
        Version = $Version
        IsRelease = $isRelease
    }
}
#mode of operation: test, manual publish, auto publish
function Test-Data
{
    # for test only	 
    Write-Host "======Test or re-publish artifacts manually===== "
	# to ree-publish artifacts manually, set SIGNPATH_SIGNING_REQUESt_ID
	 $env:SIGNPATH_SIGNING_REQUEST_STATUS = "Completed"
     #Sr v6.3.2
	 $env:SIGNPATH_SIGNING_REQUESt_ID= '79df1eb7-859b-4e6a-970a-ecbde334411f'
	 #$env:VERSION='6.3.3'
     #$env:TEST_SIGNING='true' 
     $env:Signing_Mode='manual'  #test, manual, auto
     write-host "env:Signing_Mode= $($env:Signing_Mode)"
}

Function Main 
{
     param ( [string]$FolderPath)
     #set test environment
	 Test-Data
	 
	 if ( $env:SIGNPATH_SIGNING_REQUEST_STATUS -eq "Completed") {
       $env:SIGNING='true'      
      }
      else { 
        Write-Host "Stop execution. SIGNING_REQUEST_STATUS = $($env:SIGNPATH_SIGNING_REQUEST_STATUS)"
        $env:SIGNING='false'         
		return
      }

      # In test don't publish package
      if ($env:TEST_SIGNING -eq 'true') { 
      $env:SIGNING='false' 
      } 

	  Print-Request
	  $env:SIGNPATH_SIGNING_REQUESt_ID | Set-Content "sr.txt"
	  $artifact='./artifacts.zip'
      Download-Artifacts $artifact     
	  unZip -Path $artifact
	  Get-ChildItem -Path './signed' -Recurse
	  #$version=Get-Version  './signed'
      Get-Version  $FolderPath
      Write-Host "env:SignVersion = $($env:SignVersion)"
      Write-Host "env:SIGNING = $($env:SIGNING)"
      Write-Host "Artifacts will be pushed to GitHub TAG: $($env:SignVersion)"
	  
}