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
    1. Copies Workspace ONE Factory Provisioning PPKG and unattend.xml files to Recovery folder to get same experience during Device Reset with Provisioning Data
        a.    AirwatchAgent.msi copied to C:\Recovery\OEM folder if exists in this package. 
        b.    unattend.xml copied to C:\Recovery\AutoApply folder. 
        b.    PPKG copied to C:\Recovery\Customization folder if exists in this package. 
              Assists with 'brownfield' Windows 10 device to provide over-the-air rebuild to a 'known good state'
              i.    This option can be used in conjunction with Agent Only Enrolment flow, eg. AirLift SCCM Migration & Enrolment
              ii.   This option will overwrite the existing PPKG.
    
    Brownfield Devices:
    This script can be used to push the Workspace ONE Factory Provisioning files to a device even if it wasn't provisioned with Workspace ONE Factory Provisioning.
    This is helpful where you want to take advantage of the ability to reprovision/rebuild a device over-the-air.
    Workspace ONE Factory Provisioning Package file (PPKG)
      NOTE: Include only one PPKG file in the package folder. PPKG can be called anything, eg. ce05a86f-0599-4559-b2f4-35104226ea53.ppkg.

    WS1 Application parameters:
      Install command: powershell.exe -ep bypass -file .\DeviceWipeWProvisioning.ps1
      Uninstall command: powershell.exe Remove-Item -Path "C:\Recovery\OEM\VMwareResetRecover.cmd" -Force -Recurse
      Install Complete: file exists - C:\Recovery\OEM\VMwareResetRecover.cmd

    Install Command: powershell.exe -ep bypass -file .\DeviceWipeWProvisioning.ps1
    Uninstall Command: .
    Installer Success Exit Code: 0
    When to Call Install Complete: File Exists C:\Recovery\AutoApply\unattend.xml

  .REQUIREMENTS
    1. Device enrolled into a Workspace ONE environment. Does not need to be the target environment.
    2. WS1 Intelligent Hub (AirwatchAgent.msi) added to ZIP. 
        In a browser, goto https://<DS_FQDN>/agents/ProtectionAgent_AutoSeed/AirwatchAgent.msi to download it, 
        substituting <DS_FQDN> with the FQDN for their Device Services Server. Why do this, because the version from https://getwsone.com is the latest shipping version, 
        not the one seeded into the console that is deployed to new devices or upgraded to on existing devices after the console is upgraded.
    2. WinRE partition on the device with Windows RE boot image (Winre.wim) available on System drive
        https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/pbr-faq
    3. Workspace ONE Factory Provisioning unattend.xml. 
        NOTE: Include only one XML file in the package folder. Unattend.xml can be called anything, eg myunatten.xml, and long filenames are supported.
    
  .EXAMPLE
    Deploy relevant components to a WS1 Windows 10 machine ready for Device Wipe with Provisioning Data call
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

#Copy AirwatchAgent.msi
#Need to find a way to leverage the latest version already installed on the device. Doesn't appear to be copied to 
#C:\Recovery\OEM and %programdata%\VMware when upgraded. AirwatchAgent.msi stored in C:\Recovery\OEM and %programdata%\VMware are the original versions.
$airwatchagent = Get-ChildItem -Path $current_path -Include *AirwatchAgent.msi* -Recurse -ErrorAction SilentlyContinue
$OEMPATH = "C:\Recovery\OEM"
$file = "AirwatchAgent.msi"
Set-TargetResource -Path $OEMPATH -File $file -FiletoCopy $airwatchagent

#Copy PPKG
$PPKG = Get-ChildItem -Path $current_path -Include *.ppkg* -Recurse -ErrorAction SilentlyContinue
$CustomPATH = "C:\Recovery\Customizations"
$file = $PPKG.Name
#Remove existing PPKG
write-host "Removing existing PPKG"
Remove-Item -Path $CustomPATH -Include *.ppkg* -Recurse -ErrorAction SilentlyContinue
Set-TargetResource -Path $CustomPATH -File $file -FiletoCopy $PPKG

#If Reset, Unattend & PPKG files all exist, then continue
If (!$FileExists){$exitcode = 1;exit $exitcode}
