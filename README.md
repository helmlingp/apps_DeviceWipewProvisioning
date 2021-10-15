# apps_DeviceWipewProvisioning
Copies Workspace ONE Factory Provisioning PPKG and unattend.xml files to Recovery folder to get the same OOBE and Domain Join experience during 
Device Reset with Provisioning Data as a brand new Factory Provisioned/DropShip Provisioned device. Completes the following tasks:
a.    unattend.xml copied to C:\Recovery\AutoApply folder. 
      **NOTE:** Include only one unattend XML file in the package folder. Unattend.xml can be called anything, eg myunatten.xml, and long filenames are supported.
b.    (OPTIONAL) AirwatchAgent.msi copied to C:\Recovery\OEM folder if exists in this package. 
c.    (OPTIONAL) PPKG copied to C:\Recovery\Customization folder if exists in this package. 
      Assists with 'brownfield' Windows 10 device to provide over-the-air rebuild to a 'known good state'
      i.    This option can be used in conjunction with Agent Only Enrolment flow, eg. AirLift SCCM Migration & Enrolment
      ii.   This option will overwrite the existing PPKG.
      **NOTE:** Include only one PPKG file in the package folder. PPKG can be called anything, eg. ce05a86f-0599-4559-b2f4-35104226ea53.ppkg.

**REQUIREMENTS**
1. Device enrolled into a Workspace ONE environment. Does not need to be the target environment.
2. Workspace ONE Factory Provisioning unattend.xml. 
   NOTE: Include only one XML file in the package folder. Unattend.xml can be called anything, eg myunatten.xml, and long filenames are supported.
3. WS1 Intelligent Hub (AirwatchAgent.msi). To obtain the correct version to match your console, 
   in a browser goto https://<DS_FQDN>/agents/ProtectionAgent_AutoSeed/AirwatchAgent.msi to download it, substituting <DS_FQDN> with the FQDN 
   for their Device Services Server. Why do this, because the version from https://getwsone.com is the latest shipping version, 
   not the one seeded into the console that is deployed to new devices or upgraded to on existing devices after the console is upgraded.
5. WinRE partition on the device with Windows RE boot image (Winre.wim) available on System drive
   https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/pbr-faq

**Brownfield Devices**
This script can be used to push the Workspace ONE Factory Provisioning files to a device even if it wasn't provisioned with Workspace ONE Factory Provisioning.
This is helpful where you want to take advantage of the ability to reprovision/rebuild a device over-the-air.
