@echo off
REM Copyright © 2018 VMware, Inc. All rights reserved.
REM This product is protected by copyright and intellectual property laws in the United States and 
REM other countries as well as by international treaties.
REM VMware products may be covered by one or more patents listed at http://www.vmware.com/go/patents 

REM This script Restores data and settings from \Recovery\OEM folder. 
REM Windows Refresh migrates \Recovery\OEM folder from Old PC to New PC
REM 1115

setlocal enabledelayedexpansion
REM Allowing saving debug information
SET DEBUGAWSCRIPT=FALSE

REM "Workspace ONE Intelligent Hub" Product GUID
SET AWAGENT=CCC1E1C6-DFFA-D6FD-88EE-01A935B36531
REM AirWatchMDM Agent Product GUID
SET AWMDMAGENT=6A95E4DE-6297-4062-8F5F-95AF704D3A85
REM AW Provisioning Agent Product name
SET AWPROVAGENT=ProvisioningAgent
SET AWINSTALLDIR=Program Files (x86)\AirWatch

REM Installation directories
SET TARGETOS=C:\Windows
SET OEMPATH=recovery\oem
SET AUTOAPPLY=recovery\AutoApply
SET VMWAREPATH=%OEMPATH%\VMware
SET TARGETOSDRIVE=C:
SET MDMDEVICEID=MDMDeviceID
SET MSIINSTALLER=Installer
SET AWDATA="%TARGETOSDRIVE%\ProgramData\AirWatchMDM\AppDeploymentCache"

REM Define %TARGETOS% as the Windows folder (This later becomes C:\Windows) 
for /F "tokens=1,2,3 delims= " %%A in ('reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RecoveryEnvironment" /v TargetOS') DO SET TARGETOS=%%C

REM Define %TARGETOSDRIVE% as the Windows partition (This later becomes C:)
for /F "tokens=1 delims=\" %%A in ('Echo %TARGETOS%') DO SET TARGETOSDRIVE=%%A

SET LOGFILE="%TARGETOSDRIVE%\%VMWAREPATH%\recoverylog.txt"

echo : >>%LOGFILE%
echo Recovering Data and Settings >>%LOGFILE%
echo STARTED at %time%  >>%LOGFILE%
	echo : >>%LOGFILE%
	echo Copying files and settings >>%LOGFILE%
		rem call :SUB_CopyFS "SFD Cache" "%TARGETOSDRIVE%\%VMWAREPATH%\AppDeploymentCache" "%AWDATA%"

	echo Load Registry Software hive and restore >>%LOGFILE%
	SET TOPREGKEYNAME=HKLM\AirWatchRefresh
	rem reg load %TOPREGKEYNAME% %TARGETOS%\System32\Config\SOFTWARE
		rem call :SUB_RESTORE_HIVE %TOPREGKEYNAME%\AirWatchMDM "%TARGETOSDRIVE%\%VMWAREPATH%\Registry\%AWMDMAGENT%.hive"
	
	echo Add Custom Registry Changes for OOBE >>%LOGFILE%
	rem reg add “HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE” /v “PrivacyConsentStatus” /t REG_DWORD /d 1 /f

	rem reg unload %TOPREGKEYNAME%
	echo Done restoring HIVEs >>%LOGFILE%

	REM Copy unattend.xml to c:\Recovery\AutoApply overwring previous
	echo : >>%LOGFILE%
	echo Copy unattend.xml to Recovery\OEM folder >>%LOGFILE%
	if exist "%TARGETOSDRIVE%\%OEMPATH%\AWResetUnattend.xml" (
		REM SET %TargetOSDrive% in the unattend.xml
		echo Copying %TARGETOSDRIVE%\%OEMPATH%\AWResetUnattend.xml to %TARGETOS%\Panther\unattend.xml >>%LOGFILE%
		copy "%TARGETOSDRIVE%\%OEMPATH%\AWResetUnattend.xml" "%TARGETOS%\Panther\Unattend.xml" /y
		rem copy %TARGETOSDRIVE%\%OEMPATH%\AWResetUnattend.xml %TARGETOSDRIVE%\%AUTOAPPLY%\unattend.xml /Y

		if exist "%TARGETOS%\Panther\Unattend.xml" (
		rem if exist "%TARGETOSDRIVE%\%AUTOAPPLY%\unattend.xml" (
			echo %TARGETOS%\Panther\Unattend.xml succesfully created >>%LOGFILE%
			goto SUCCESS
		)		
	)
	SET CURRENTERROR="ERROR: %TARGETOS%\Panther\unattend.xml does not exist"
	echo ERROR: %TARGETOS%\Panther\unattend.xml does not exist >>%LOGFILE%
	goto REVERT

:SUCCESS
echo : >>%LOGFILE%
echo Succesufully complete Restore operations >>%LOGFILE%
echo FINISHED at %time%  >>%LOGFILE%
exit /b 0

:REVERT
echo : >>%LOGFILE%
echo %CURRENTERROR% >>%LOGFILE%
echo FINISHED at %time%  >>%LOGFILE%
if /I NOT "%DEBUGAWSCRIPT%"=="TRUE" (
	rmdir %TARGETOSDRIVE%\%VMWAREPATH%\Registry /S /Q
	rmdir %TARGETOSDRIVE%\%VMWAREPATH%\AppDeploymentCache /S /Q
)
exit /b 1111

REM Copy files and directories from inactive FileSystem to OEM folder
:SUB_CopyFS Title SOURCE DESTINATION
	SET TITLE=%~1
	SET SOURCE=%~2
	SET DESTINATION=%~3
	echo Restore %TITLE% from %SOURCE% to %DESTINATION% >>%LOGFILE%	
	if exist %SOURCE% (
	    robocopy "%SOURCE%" "%DESTINATION%" /s >>%LOGFILE%
		if %ERRORLEVEL% EQU 16 ("ERROR: Cannot restore %TITLE% from %SOURCE% to %DESTINATION%" >>%LOGFILE% & exit /b 1001)
		echo %TITLE% succesfully restored >>%LOGFILE%
	) else (
		echo %TITLE% %SOURCE% does not exist. Skipping restore >>%LOGFILE%
	)
exit /b 0

REM Restores saved HIVE from OEM\Registry folder
:SUB_RESTORE_HIVE Title Source
	SET TITLE=%~1
	SET SOURCE=%~2
	echo Restore %TITLE% from %SOURCE% >>%LOGFILE%
	if exist %SOURCE% (
		echo %SOURCE% exist. Restoring to Registry %TITLE% >>%LOGFILE%
		reg add %TITLE% >>%LOGFILE%
		reg restore %TITLE% %SOURCE% >>%LOGFILE%
		if ERRORLEVEL 1 ( echo ERROR: Cannot restore %TITLE% from %SOURCE% >>%LOGFILE% & exit /b 1001)
		echo %TITLE% succesfully restored >>%LOGFILE%
	) else (
		echo ERROR: %SOURCE% does not exist >>%LOGFILE% & exit /b 1002
	)
exit /b 0
