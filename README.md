# apps_DeviceWipewProvisioning
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
