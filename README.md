# apps_DeviceWipewProvisioning
Copies files needed to use Workspace ONE Factory Provisioning PPKG and unattend.xml during Device Reset with Provisioning Data.
a.    Files copied to C:\Recovery\OEM folder to configure Windows on Device Reset and OOBE.
b.    Also copies PPKG to C:\Recovery\Customization if exists in this package. Assists with 'brownfield' Windows 10 device to provide over-the-air rebuild to a 'known good state'
   i.    This option can be used in conjunction with Agent Only Enrolment flow, eg. AirLift SCCM Migration & Enrolment
   ii.   This option will overwrite the existing PPKG.
Calls Push Button Reset (Device Wipe with Provisioning Data) if -Reset flag provided

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
