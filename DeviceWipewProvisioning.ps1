<#	
  .Synopsis
    Copies files needed to use Workspace ONE Factory Provisioning PPKG and unattend.xml during Device Reset with Provisioning Data
  .NOTES
	  Created:   	    October, 2020
	  Created by:	    Phil Helmling, @philhelmling
	  Organization:   VMware, Inc.
	  Filename:       DeviceWipeWProvisioning.ps1
    Updated:        March, 2021
	.DESCRIPTION
1. Copies files needed to use Workspace ONE Factory Provisioning PPKG and unattend.xml during Device Reset with Provisioning Data.
    a.    Files copied to C:\Recovery\OEM folder to configure Windows on Device Reset and OOBE.
    b.    Also copies PPKG to C:\Recovery\Customization if exists in this package. Assists with 'brownfield' Windows 10 device to provide over-the-air rebuild to a 'known good state'
        i.    This option can be used in conjunction with Agent Only Enrolment flow, eg. AirLift SCCM Migration & Enrolment
        ii.   This option will overwrite the existing PPKG.
2. Calls Push Button Reset (Device Wipe with Provisioning Data) if -Reset flag provided

REQUIREMENTS:
1. WS1 Intelligent Hub (AirwatchAgent.msi) installed and Device enrolled. Requires other components already copied to C:\Recovery\OEM folder.
2. WinRE partition on the device with Windows RE boot image (Winre.wim) available on the local hard drive
    https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/pbr-faq
3. Workspace ONE Factory Provisioning unattend.xml. 
    NOTE: Include only one XML file in the package folder. Unattend.xml can be called anything, eg myunatten.xml.

OPTIONAL Brownfield Devices:
1. Workspace ONE Factory Provisioning Package file (PPKG)
    NOTE: Include only one PPKG file in the package folder. PPKG can be called anything, eg. myprovisioningpackage.ppkg.
2. -Reset script switch parameter will initiate a Device Wipe with Provisioning Data call to the MDM CSP RemoteWipe
    https://deviceadvice.io/2019/04/26/powershell-run-mdm-csps-locally/
    
    WS1 Application parameters:
    Install command: powershell.exe -ep bypass -file .\DeviceWipeWProvisioning.ps1
    Uninstall command: powershell.exe Remove-Item -Path "C:\Recovery\OEM\VMwareResetRecover.cmd" -Force -Recurse
    Install Complete: file exists - C:\Recovery\OEM\VMwareResetRecover.cmd
    
  .EXAMPLE
    Deploy relevant components to a WS1 Windows 10 machine ready for Device Wipe with Provisioning Data call
    powershell.exe -ep bypass -file .\DeviceWipeWProvisioning.ps1

    Deploy relevant components to a WS1 Windows 10 machine and call Device Wipe with Provisioning Data
    powershell.exe -ep bypass -file .\DeviceWipeWProvisioning.ps1 -Reset
#>
param (
    [Parameter(Mandatory=$false)]
    [Switch]$Reset
)

$current_path = $PSScriptRoot;
if($PSScriptRoot -eq ""){
    #PSScriptRoot only popuates if the script is being run.  Default to default location if empty
    $current_path = "C:\Temp";
}

$unattend = Get-ChildItem -Path $current_path -Include *.xml* -Recurse -Exclude ResetConfig.xml -ErrorAction SilentlyContinue

function Test-FileExists {
    [OutputType('bool')]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$File
    )

    $ErrorActionPreference = 'Stop'

    if (Test-Path $File -PathType leaf -ErrorAction Ignore) {
        $true
    }
}

Function TestforUnattendFiles {
  $tests = @(
        { Test-FileExists -File "$OEMPATH\AWResetUnattend.xml" }
        { Test-FileExists -File "$OEMPATH\ResetConfig.xml" }
        { Test-FileExists -File "$OEMPATH\VMwareResetRecover.cmd" }
        { Test-FileExists -File "$OEMPATH\AirwatchAgent.msi" }
  )

  foreach ($test in $tests) {
      Write-Verbose "Running Tests: [$($test.ToString())]"
      if (& $test) {
          $FileExists = $true
          break
      }
  }
  return $FileExists
}

Function TestforPPKGFiles {
  $tests = @(
        { Test-FileExists -File "$CustomPATH\$PPKG" }
  )

  foreach ($test in $tests) {
      Write-Verbose "Running Tests: [$($test.ToString())]"
      if (& $test) {
          $FileExists = $true
          break
      }
  }
  return $FileExists
}

$OEMPATH = "C:\Recovery\OEM"
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
    Copy-Item -Path "$current_path\AirwatchAgent.msi" -Destination $OEMPATH -Force
  }
  #Test if the necessary files exist
  $FileExists = TestforUnattendFiles
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
  #Test if the necessary files exist
  $FileExists = TestforPPKGFiles
}

#If Reset, Unattend & PPKG files all exist, then continue
If (!$FileExists){$exitcode = 1;exit $exitcode}

if ($Reset) {
  
  write-host "Starting Reset"

  if ($FileExists) {
    #Initiate Device Wipe with Provisioning
    $namespaceName = "root\cimv2\mdm\dmmap"
    $className = "MDM_RemoteWipe"
    $methodName = "doWipePersistProvisionedDataMethod" 
    #https://docs.microsoft.com/en-us/windows/client-management/mdm/remotewipe-csp methods with "Method" appended

    $session = New-CimSession

    $params = New-Object Microsoft.Management.Infrastructure.CimMethodParametersCollection
    $param = [Microsoft.Management.Infrastructure.CimMethodParameter]::Create("param", "", "String", "In")
    $params.Add($param)

    try
    {
        $instance = Get-CimInstance -Namespace $namespaceName -ClassName $className -Filter "ParentID='./Vendor/MSFT' and InstanceID='RemoteWipe'"
        $session.InvokeMethod($namespaceName, $instance, $methodName, $params)
    }
    catch [Exception]
    {
        write-host $_ | out-string
    }
  }

}
