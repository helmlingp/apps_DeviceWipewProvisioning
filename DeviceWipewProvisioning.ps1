<#	
  .Synopsis
    Copies Workspace ONE Factory Provisioning PPKG and unattend.xml files to Recovery folder to get same experience during Device Reset with Provisioning Data
  .NOTES
	  Created:   	    October, 2020
	  Created by:	    Phil Helmling, @philhelmling
	  Organization:   VMware, Inc.
	  Filename:       DeviceWipeWProvisioning.ps1
    Updated:        September, 2021
	.DESCRIPTION
    1. Copies unattend.xml and optionally Workspace ONE Factory Provisioning PPKG and AirwatchAgent.msi files to Recovery folder to get the same OOBE and Domain Join experience during 
    Device Reset with Provisioning Data, as a brand new Factory Provisioned/DropShip Provisioned device. 
    2. Can be used to update existing devices with new versions of the PPKG and AirwatchAgent.msi
    3. Can be used to copy unattend.xml, PPKG and AirwatchAgent.msi to devices not deployed with Workspace ONE Factory Provisioning

    Completes the following tasks:
    a.  unattend.xml copied to C:\Recovery\AutoApply folder.
        NOTE: Include only one unattend XML file in the package folder. Unattend.xml can be called anything, eg myunatten.xml, and long filenames are supported.
    b.  (OPTIONAL) AirwatchAgent.msi copied to C:\Recovery\OEM folder if exists in this package. 
    c.  (OPTIONAL) PPKG copied to C:\Recovery\Customization folder if exists in this package. 
        Assists with 'brownfield' Windows 10 device to provide over-the-air rebuild to a 'known good state'
        i.    This option can be used in conjunction with Agent Only Enrolment flow, eg. AirLift SCCM Migration & Enrolment
        ii.   This option will overwrite the existing PPKG.
        NOTE: Include only one PPKG file in the package folder. PPKG can be called anything, eg. ce05a86f-0599-4559-b2f4-35104226ea53.ppkg.

    Brownfield Devices
    This script can be used to push the Workspace ONE Factory Provisioning files to a device even if it wasn't provisioned with Workspace ONE Factory Provisioning.
    This is helpful where you want to take advantage of the ability to reprovision/rebuild a device over-the-air.

    WS1 Application parameters
    Install command: powershell.exe -ep bypass -file .\DeviceWipeWProvisioning.ps1
    Uninstall command: powershell.exe Remove-Item -Path "C:\Recovery\AutoApply\unattend.xml" -Force -Recurse
    Installer Success Exit Code: 0
    When to Call Install Complete: File Exists C:\Recovery\AutoApply\unattend.xml

  .REQUIREMENTS
    1. Device enrolled into a Workspace ONE environment. Does not need to be the target environment.
    2. Workspace ONE Factory Provisioning unattend.xml. 
        NOTE: Include only one XML file in the package folder. Unattend.xml can be called anything, eg myunatten.xml, and long filenames are supported.
    3. WS1 Intelligent Hub (AirwatchAgent.msi). To obtain the correct version to match your console, in a browser goto https://<DS_FQDN>/agents/ProtectionAgent_AutoSeed/AirwatchAgent.msi to download it, 
        substituting <DS_FQDN> with the FQDN for their Device Services Server. Why do this, because the version from https://getwsone.com is the latest shipping version, 
        not the one seeded into the console that is deployed to new devices or upgraded to on existing devices after the console is upgraded.
    4. WinRE partition on the device with Windows RE boot image (Winre.wim) available on System drive
        https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/pbr-faq
  .EXAMPLE
    Deploy relevant components to a WS1 Windows 10+ machine ready for Device Wipe with Provisioning Data call from WS1 Console
    powershell.exe -ep bypass -file .\DeviceWipeWProvisioning.ps1
#>

$current_path = $PSScriptRoot;
if($PSScriptRoot -eq ""){
    #PSScriptRoot only popuates if the script is being run.  Default to default location if empty
    $current_path = "C:\Temp";
}

function Set-TargetResource {
  param (
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Path,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$File,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$FiletoCopy
  )

  if (!(Test-Path -LiteralPath $Path)) {
    try {
      New-Item -Path $Path -ItemType Directory -ErrorAction Stop | Out-Null #-Force
    }
    catch {
      Write-Error -Message "Unable to create directory '$Path'. Error was: $_" -ErrorAction Stop
    }
    "Successfully created directory '$Path'."
  }
  Write-Host "Copying $FiletoCopy to $Path\$File"
  Copy-Item -Path $FiletoCopy -Destination "$Path\$File" -Force
  #Test if the necessary files exist
  $FileExists = Test-Path -Path "$Path\$File" -PathType Leaf
}

#Copy unattend.xml
$unattend = Get-ChildItem -Path $current_path -Include *.xml* -Recurse -Exclude ResetConfig.xml -ErrorAction SilentlyContinue
$AUTOAPPLY = "C:\Recovery\AutoApply"
$file = "unattend.xml"
Set-TargetResource -Path $AUTOAPPLY -File $file -FiletoCopy $unattend

#Copy AirwatchAgent.msi if found
#Need to find a way to leverage the latest version already installed on the device. Doesn't appear to be copied to 
#C:\Recovery\OEM and %programdata%\VMware when upgraded. AirwatchAgent.msi stored in C:\Recovery\OEM and %programdata%\VMware are the original versions.
$airwatchagent = Get-ChildItem -Path $current_path -Include *AirwatchAgent.msi* -Recurse -ErrorAction SilentlyContinue
$OEMPATH = "C:\Recovery\OEM"
$file = "AirwatchAgent.msi"
if($airwatchagent){
  Set-TargetResource -Path $OEMPATH -File $file -FiletoCopy $airwatchagent
}

#Copy PPKG if found
$PPKG = Get-ChildItem -Path $current_path -Include *.ppkg* -Recurse -ErrorAction SilentlyContinue
$CustomPATH = "C:\Recovery\Customizations"
$file = $PPKG.Name
#Remove existing PPKG
write-host "Removing existing PPKG"
if($PPKG){
  Remove-Item -Path $CustomPATH -Include *.ppkg* -Recurse -ErrorAction SilentlyContinue;
  Set-TargetResource -Path $CustomPATH -File $file -FiletoCopy $PPKG
}

#If Reset, Unattend & PPKG files all exist, then continue
If (!$FileExists){$exitcode = 1;exit $exitcode}
