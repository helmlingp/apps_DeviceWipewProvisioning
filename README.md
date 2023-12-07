# Factory Reset with Device Wipe

**Factory Resetting or Rebuilding** a Windows device over the air is possible by extending the [Windows Push Button Reset](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/how-push-button-reset-features-work?view=windows-11) capability built into Windows in conjunction with the 'Device Wipe with Provisioning Data' feature in Workspace ONE. By default, factory resetting or rebuilding devices is possible using Device Wipe, however the device will reset with factory default settings, with no OOBE customisations, domain join or automated enrolment. 

With a simple extension (the 'secret sauce') to the existing DropShip Provisioning capabilities within Workspace ONE, we can provide the exact same user experience to users when performing a Device Wipe with Provisioning Data, or initiating a device side PC Reset (Push Button Reset). The extension can be used to push a Workspace ONE DropShip Provisioning files to a device (even if it wasn't provisioned with Workspace ONE DropShip Provisioning). This is helpful where you want to take advantage of the ability to repurpose, re-provision, or rebuild a device over-the-air to a 'known good state'.
![Benefits of DWPD](/images/Screenshot%202023-05-09%20at%209.31.42%20am.png)
There are multiple use cases for Device Wipe.
![Use Cases](/images/Screenshot%202023-05-09%20at%209.30.01%20am.png)
Compare the different DropShip Provisioning with Device Wipe scenarios.
![Compare DWPD](/images/Screen%20Shot%202022-08-23%20at%208.05.46%20am.png)

And this solution will leverage the same DropShip Offline package and unattend.xml that allows you to direct ship devices to users fully configured.
![DPOffline Benefits](/images/Screenshot%202023-05-09%20at%209.23.23%20am.png)
**Note:** This can can be used in conjunction with User / Agent Enrolment flow, command line staging, and Azure AD MDM app flows. Additionally, this process can be utilised to migrate devices from one environment to another by deploying the target environment settings within the unattend.xml.

Deployed as an application from Workspace ONE UEM, this script completes the following tasks to prepare the device for Device Wipe with Provisioning Data function:
1. Copies unattend.xml to C:\Recovery\AutoApply folder. 
**NOTE:** Include only one unattend XML file in the package folder. Unattend.xml can be called anything, eg myunatten.xml, and long filenames are supported. However note that if testing manually, the file in C:\Recovery\AutoApply folder must be called unattend.xml.
2. (OPTIONAL) Copies AirwatchAgent.msi to C:\Recovery\OEM folder if exists in this package. Device Wipe with Provisioning Data will use the existing AirwatchAgent.msi file if the device has already been enrolled. Include this file within this package if requiring a specific version.
3. (OPTIONAL) Copies PPKG to C:\Recovery\Customization folder if exists in this package. Assists with 'brownfield' Windows 10+ devices not originally deployed with DropShip Provisioning to provide over-the-air rebuild to a 'known good state'. 
   3.1 This option can be used in conjunction with Agent Only Enrolment flow, eg. AirLift SCCM Migration & Enrolment
   3.2 This option will overwrite the existing PPKG.
   **NOTE:** Include only one PPKG file in the package folder. PPKG can be called anything, eg. ce05a86f-0599-4559-b2f4-35104226ea53.ppkg.

## REQUIREMENTS
1. Device enrolled into a Workspace ONE environment. Does not need to be the target environment.
2. Workspace ONE Factory Provisioning unattend.xml. 
   NOTE: Include only one XML file in the package folder. Unattend.xml can be called anything, eg myunatten.xml, and long filenames are supported.
3. WS1 Intelligent Hub (AirwatchAgent.msi). To obtain the correct version to match your console, 
   in a browser goto https://<DS_FQDN>/agents/ProtectionAgent_AutoSeed/AirwatchAgent.msi to download it, substituting <DS_FQDN> with the FQDN 
   for their Device Services Server. Why do this, because the version from https://getwsone.com is the latest shipping version, 
   not the one seeded into the console that is deployed to new devices or upgraded to on existing devices after the console is upgraded.
5. WinRE partition on the device with Windows RE boot image (Winre.wim) available on System drive
   https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/pbr-faq


# USAGE
The above-mentioned script provides a simple mechanism to create an application within Workspace ONE to deploy to devices.
## Create a DropShip Offline Provisioning Package (PPKG) and unattend.xml file
1. In the Workspace ONE UEM Console, select Devices > Lifecycle > Staging > Windows > New
2. Provide a Provisioning Package Name and Description
3. Select Drop Ship Provisioning - Offline

![DPOffline](/images/image-2023-5-9_9-46-42.png)

4. Select appropriate domain join configuration and Windows build settings. This configuration is saved into the unattend.xml

![unattend screen](/images/image-2023-5-9_9-46-51.png)

5. Select the applications to include in the Provisioning Package (PPKG) and auto-deploy to the device

![select apps](/images/image-2023-5-9_9-46-57.png)

6. Download the PPKG and unattend.xml into empty folder. Add the DeviceWipewProvisioning.ps1 script and the AirwatchAgent.msi

![package folder](/images/image-2023-5-9_9-47-4.png)

7. ZIP all four files into a ZIP file.

![ZIP package folder](/images/image-2023-5-9_9-47-10.png)

> Note: Use 7-Zip if the PPKG file is greater than 4GB in size!

## Upload the ZIP and create a Workspace ONE UEM Application
1. In the Workspace ONE UEM Console, select Resources > Apps > Native > Internal > Add > Add Application File
2. Select Upload > Browse to the new ZIP file > Save. This will upload the ZIP file to the console which could take some time if the file is large.
3. Add the following attributes to the new Windows Application:

Attribute   | Parameter
---   |  ---:
Install command:   |  `powershell.exe -ep bypass -file .\DeviceWipeWProvisioning.ps1`
Uninstall command: |  `powershell.exe Remove-Item -Path "C:\Recovery\AutoApply\unattend.xml" -Force -Recurse`
Installer Success Exit Code:  |  0
When to Call Install Complete:   |  File Exists C:\Recovery\AutoApply\unattend.xml


## Initiate a Factory Reset
There are three methods to initiating a reset, 2 are user initiated and 1 admin initiated.

### 1. Manageable (Working) Devices (Admin Initiated)
This method is suitable if the device is operating and manageable.
1. View the details of the machine > More Actions > Device Wipe

![Device Wipe](/images/Screen%20Shot%202021-10-15%20at%201.53.17%20pm.png)

2. Select Device Wipe with Provisioning Data from the "Please select the wipe action you wish to take" dropdown > Continue > enter your console admin pin code > Continue

![DWSelection](/images/image2022-8-23_8-6-45.png)

![DWDP](/images/Screen%20Shot%202021-10-15%20at%201.53.46%20pm.png)

This will send a doWipePersistProvisionedData CSP command to the device. The Device should begin the reset process almost instantly. If not, there maybe WNS connectivity issues.

3. Monitor the device wipe status

![Monitor](/images/Screen%20Shot%202021-10-15%20at%201.55.22%20pm.png)

The device should reset and reboot to the OOBE screen and follow the same OOBE flow as Factory Provisioned devices.

### 2. Unmanageable (Working) Device (User Initiated)
If a device is not manageable, for example the Workspace ONE Intelligent Hub has been uninstalled or an Enterprise Wipe has been initiated, then the user can initiate a 'Reset this PC' from System > Recovery.
1. Open System Settings
2. Select Recovery > 'Reset this PC' and follow the prompts to reset with local image

![Reset this PC](/images/Screenshot%202023-05-09%20at%2011.53.30%20am.png)

### 3. Unmanageable and non-working Device (User Initiated)
If the device won't boot into Windows or allow user authentication, for example where an Enterprise Wipe is performed on an Azure AD joined device and there is no local Administrator account enabled, the user or admin can boot into the Windows Recovery Console and initiate the Reset My PC process directly from the local device.

1. From the sign-in screen press the Windows logo key + L or Ctrl-Alt-Del and then restart your PC by pressing the Shift key while you select the Power button > Restart in the lower-right corner of the screen.
2. The device will restart in the Windows Recovery Environment (WinRE) environment.
3. On the Choose an option screen, select Troubleshoot > Reset this PC > Remove everything.

![Choose an Option](/images/image-2023-5-9_12-2-46.png) ![Troubleshoot](/images/image-2023-5-9_12-3-12.png) ![Reset this PC](/images/image-2023-5-9_12-3-21.png)

4. If the device was Bitlocker encrypted with TPM, the recovery key will be required

![PC Reset Bitlocker](/images/image-2023-5-9_12-3-30.png)

> As described above, Push Button Reset is utilised by the 'Device Wipe' to initiate a reset and reinstall of the OS, with the option to keep or delete user data and applications.

