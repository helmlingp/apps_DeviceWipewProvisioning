<#	
  .Synopsis
    Reapplies Workspace ONE Factory Provisioning PPKG and unattend.xml at Device Reset with Provisioning Data
  .NOTES
	  Created:   	    October, 2020
	  Created by:	    Phil Helmling, @philhelmling
	  Organization:   VMware, Inc.
	  Filename:       DeviceWipeWProvisioning.ps1
	.DESCRIPTION
    Reapplies Workspace ONE Factory Provisioning PPKG and unattend.xml at Device Reset with Provisioning Data.
    Copies files to C:\Recovery\OEM folder to be used by Push Button Reset (Device Wipe) process.
    
    Include Workspace ONE Factory Provisioning unattend.xml used for original deployment
    in package folder before ZIP'ing. Unattend.xml can be called anything, eg myunatten.xml.
    
    No other modifications required to this package.

    Install command: powershell.exe -ep bypass -file .\DeviceWipeWProvisioning.ps1
    Uninstall command: powershell.exe Remove-Item -Path "C:\Recovery\OEM\VMwareResetRecover.cmd" -Force -Recurse
    Install Complete: file exists - C:\Recovery\OEM\VMwareResetRecover.cmd
    
  .EXAMPLE
    powershell.exe -ep bypass -file .\DeviceWipeWProvisioning.ps1

#>

$current_path = $PSScriptRoot;
if($PSScriptRoot -eq ""){
    #PSScriptRoot only popuates if the script is being run.  Default to default location if empty
    $current_path = "C:\Temp";
}

$OEMPATH = "C:\Recovery\OEM"
$unattend = Get-ChildItem -Path $current_path -Include *.xml* -Recurse -Exclude ResetConfig.xml -ErrorAction SilentlyContinue

if(!$unattend){
  #Fail
  Write-Host "Cannot find unattend.xml"
} else {
  if (-not (Test-Path -LiteralPath $OEMPATH)) {
    
    try {
        New-Item -Path $OEMPATH -ItemType Directory -ErrorAction Stop | Out-Null #-Force
    }
    catch {
        Write-Error -Message "Unable to create directory '$OEMPATH'. Error was: $_" -ErrorAction Stop
    }
    "Successfully created directory '$OEMPATH'."
  } else {
    Write-Host "Copying files"
    Copy-Item -Path $unattend -Destination "$OEMPATH\AWResetUnattend.xml" -Force
    Copy-Item -Path "$current_path\ResetConfig.xml" -Destination $OEMPATH -Force
    Copy-Item -Path "$current_path\VMwareResetRecover.cmd" -Destination $OEMPATH -Force
  }
}
#  $OEMPATHExists = Get-Item -Path $OEMPATH
<#   if($OEMPATHExists){
    Write-Host "Copying files"
    Copy-Item -Path $unattend -Destination "$OEMPATH\AWResetUnattend.xml" -Force
    Copy-Item -Path "$current_path\ResetConfig.xml" -Destination $OEMPATH -Force
    Copy-Item -Path "$current_path\VMwareResetRecover.cmd" -Destination $OEMPATH -Force
  } Else {
    #fail
    Write-Host "Cannot find C:\Recovery\OEM folder, no Press Button Reset available on this machine."
  }
} #>
