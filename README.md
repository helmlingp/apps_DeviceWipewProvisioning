# apps_DeviceWipewProvisioning
 Reapplies Workspace ONE Factory Provisioning PPKG and unattend.xml at Device Reset

 Copies files to C:\Recovery\OEM folder to be used by Push Button Reset (Device Wipe) process.
    
 Include Workspace ONE Factory Provisioning unattend.xml used for original deployment
 in package folder before ZIP'ing. Unattend.xml can be called anything.xml
    
 No other modifications required to this package.

 Install command: powershell.exe -ep bypass -file .\DeviceWipeWProvisioning.ps1
 Uninstall command: powershell.exe Remove-Item -Path "C:\Recovery\OEM\VMwareResetRecover.cmd" -Force -Recurse
 Install Complete: file exists - C:\Recovery\OEM\VMwareResetRecover.cmd