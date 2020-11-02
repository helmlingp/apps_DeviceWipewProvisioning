<#	
  .Synopsis
    Reapplies Workspace ONE Factory Provisioning PPKG and unattend.xml at Device Reset
  .NOTES
	  Created:   	    October, 2020
	  Created by:	    Phil Helmling, @philhelmling
	  Organization:   VMware, Inc.
	  Filename:       DeviceWipeWProvisioning.ps1
	.DESCRIPTION
    Reapplies Workspace ONE Factory Provisioning PPKG and unattend.xml at Device Reset and
    Device Reset with Provisioning Data. 
    Copies files to C:\Recovery\OEM and C:\Recovery\AutoApply folder to be used by Push Button Reset (Device Wipe) process.
    
    Requires the inclusion of Workspace ONE Factory Provisioning unattend.xml used for original deployment
    in package folder before ZIP'ing. Unattend.xml can be called anything.xml
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
$AUTOAPPLY = "C:\Recovery\AutoApply"
$unattend = Get-ChildItem -Path $current_path -Include *.xml* -Recurse -Exclude ResetConfig.xml -ErrorAction SilentlyContinue

if(!$unattend){
  #Fail
  Write-Host "Cannot find unattend.xml"
} else {
  $OEMPATHExists = Get-Item -Path $OEMPATH
  $AUTOAPPLYExists = Get-Item -Path $AUTOAPPLY
  if($OEMPATHExists){
    Write-Host "Copying files"
    Copy-Item -Path $unattend -Destination "$OEMPATH\AWResetUnattend.xml" -Force
    Copy-Item -Path "$current_path\ResetConfig.xml" -Destination $OEMPATH -Force
    Copy-Item -Path "$current_path\VMwareResetRecover.cmd" -Destination $OEMPATH -Force
    if($AUTOAPPLYExists){
      Copy-Item -Path $unattend -Destination "$AUTOAPPLY\unattend.xml" -Force
    } Else {
      New-Item -Path $AUTOAPPLY -ItemType Directory -Force
      Copy-Item -Path $unattend -Destination "$AUTOAPPLY\unattend.xml" -Force
    }
  } Else {
    #fail
    Write-Host "Cannot find C:\Recovery\OEM folder, no Press Button Reset available on this machine."
  }
}
