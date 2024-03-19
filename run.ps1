# Copyright (c) Mohamed Hassan. All rights reserved. See License.md in the project root for license information.

#manuall download artifacts
Function Get-Request
{
  param ([string] $fileName = "tag.txt")
  $request = Get-Content -Path $fileName | ConvertFrom-StringData
  $env:SignVersion = $request.Tag
  $env:SIGNPATH_SIGNING_REQUEST_STATUS = "Completed"   
  $env:SIGNPATH_SIGNING_REQUESt_ID = $request.Sr
  write-host "Tag Version: $($request.Tag)"
  $request
}

Function Get-Sha256 {
    param ([string] $directoryPath)
    Get-Location 

    $files = Get-ChildItem  -Path $directoryPath -Include *.nupkg, *.exe -Recurse

    foreach ($file in $files) {
        $fileName = $file.Name
        $fileSize = $file.Length
        $sha256Hash = Get-FileHash -Path $file.FullName -Algorithm SHA256 | Select-Object -ExpandProperty Hash
        #$createdOn = $file.CreationTime

        # Print the information
        Write-Host "File Name: $fileName"
        Write-Host "Size: $fileSize bytes"
        Write-Host "SHA-256 Hash: $sha256Hash"
        Write-Host "-------------------------"
    }
}


#Get-Sha256 $directoryPath
Function Write-Request {
    Write-Output "SIGNPATH_ORGANIZATION_ID: $($env:SIGNPATH_ORGANIZATION_ID)"
    Write-Output "SIGNPATH_SIGNING_REQUESt_ID: $($env:SIGNPATH_SIGNING_REQUEST_ID)"
    Write-Output "SIGNPATH_SIGNING_REQUEST_STATUS: $($env:SIGNPATH_SIGNING_REQUEST_STATUS)"
    Write-Output "APPVEYOR_REPO_TAG_NAME: $($env:APPVEYOR_REPO_TAG_NAME)"
}

Function Download-Artifacts {
    param ([string]$Output)
    $CI_USER_TOKEN = $env:SIGNPATH_CI_USER_TOKEN
    $SIGNING_REQUEST_ID = $env:SIGNPATH_SIGNING_REQUESt_ID
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

Function unZip {
    param (
        [string]$Path,
        [string]$Destination = '.\signed'  
    )
    Expand-Archive -LiteralPath $Path  -DestinationPath $Destination -Force
    Get-Sha256   .\signed
}

# set environment variables env:SignVersion
function Get-Version {    
    param ( [string]$FolderPath)
    $fileName = Get-ChildItem -Path $FolderPath -Filter "*.nupkg" |  Select-Object -First 1     
    write-host $fileName 
    $version = [regex]::Match($fileName, '\d+\.\d+\.\d+(-[\w\d-]+)?').Value
    $version = "v" + $version
    $isRelease = $version -match '^\d+\.\d+\.\d+$'
    #set environment
    $env:IS_RELEASE = 'false'
    if ($isRelease -eq $true) {
        $env:IS_RELEASE = 'true'
    } 
    $env:SignVersion = $Version
    write-host "Package Version: $Version"

    return [PSCustomObject]@{
        Version   = $Version
        IsRelease = $isRelease
    }
}
#mode of operation: test, manual publish, auto publish
function Test-Data {
    # for test only	 
    Write-Host "======Test or re-publish artifacts manually===== "
    # to ree-publish artifacts manually, set SIGNPATH_SIGNING_REQUESt_ID
    $env:SIGNPATH_SIGNING_REQUEST_STATUS = "Completed"
    #Sr v6.3.2
    $env:SIGNPATH_SIGNING_REQUESt_ID = '79df1eb7-859b-4e6a-970a-ecbde334411f'
    #$env:VERSION='6.3.3'
    #$env:TEST_SIGNING='true' 
    $env:Signing_Mode = 'manual'  #test, manual, auto
    write-host "env:Signing_Mode= $($env:Signing_Mode)"
}

Function Main {
    param ( [string]$FolderPath = '.\signed')
    #set test environment
    #Test-Data #test only
	Get-Request  #manual download artifacts 
    if ( $env:SIGNPATH_SIGNING_REQUEST_STATUS -eq "Completed") {
        $env:SIGNING = 'true'      
    }
    else { 
        Write-Host "Stop execution. SIGNING_REQUEST_STATUS = $($env:SIGNPATH_SIGNING_REQUEST_STATUS)"
        $env:SIGNING = 'false'         
        return
    }

    # In test don't publish package
    if ($env:TEST_SIGNING -eq 'true') { 
        $env:SIGNING = 'false' 
    } 

    Write-Request
    $env:SIGNPATH_SIGNING_REQUESt_ID | Set-Content "sr.txt"
    $artifact = './artifacts.zip'
    Download-Artifacts $artifact     
    unZip -Path $artifac
           
    #Get-Version  $FolderPath
    Write-Host "env:SignVersion = $($env:SignVersion)"
    Write-Host "env:SIGNING = $($env:SIGNING)"
    Write-Host "Signed Artifacts will be pushed to GitHub TAG: $($env:SignVersion)"
	  
}