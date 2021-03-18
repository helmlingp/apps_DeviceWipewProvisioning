<#	
  .Synopsis
    Reapplies Workspace ONE Factory Provisioning PPKG and unattend.xml at Device Reset with Provisioning Data
  .NOTES
	  Created:   	    October, 2020
	  Created by:	    Phil Helmling, @philhelmling
	  Organization:   VMware, Inc.
	  Filename:       DeviceWipeWProvisioning.ps1
    Updated:        March, 2021
	.DESCRIPTION
    Reapplies Workspace ONE Factory Provisioning PPKG and unattend.xml at Device Reset with Provisioning Data.
    Copies files included in this package to C:\Recovery\OEM folder to be used by Push Button Reset (Device Wipe) process.
    
    *New - add capability to deploy to 'brownfield' Windows 10 device to provide over-the-air rebuild to a 'known good state'
    It does this by copying the PPKG file included in this package to C:\Recovery\Customizations
    This option can be used in conjunction with Agent Only Enrolment flow, eg. AirLift SCCM Migration & Enrolment
    This option will overwrite the existing PPKG.

    REQUIREMENTS:
    1. WS1 Intelligent Hub (AirwatchAgent.msi) installed and Device enrolled
    2. WinRE partition on the device with Windows RE boot image (Winre.wim) available on the local hard drive
    https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/pbr-faq
    
    IMPORTANT:
    1. Please include the Workspace ONE Factory Provisioning unattend.xml used for original deployment in package folder before ZIP'ing.
    2. Include only one XML file in the package folder.
    3. Unattend.xml can be called anything, eg myunatten.xml.
    
    OPTIONAL Brownfield Devices:
    1. Include Workspace ONE Factory Provisioning Package file (PPKG) used for original deployment in package folder before ZIP'ing.
    2. Include only one PPKG file in the package folder.
    3. PPKG can be called anything, eg. myprovisioningpackage.ppkg.
    
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

$CustomPATH = "C:\Recovery\Customizations"
$PPKG = Get-ChildItem -Path $current_path -Include *.ppkg* -Recurse -ErrorAction SilentlyContinue
if(!$PPKG){
  #Don't do anything
} else {
  if (-not (Test-Path -LiteralPath $CustomPATH)) {
    
    try {
        New-Item -Path $CustomPATH -ItemType Directory -ErrorAction Stop | Out-Null #-Force
    }
    catch {
        Write-Error -Message "Unable to create directory '$CustomPATH'. Error was: $_" -ErrorAction Stop
    }
    "Successfully created directory '$CustomPATH'."
  } else {
    Write-host "Removing existing PPKG file"
    Remove-Item -Path $CustomPATH -Include *.ppkg* -Recurse -ErrorAction SilentlyContinue
    Write-Host "Copying files"
    Copy-Item -Path $PPKG -Destination $CustomPATH -Force
  }
}