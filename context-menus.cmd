@echo off
setlocal

if /I "%~1"=="-a" goto :install
if /I "%~1"=="-r" goto :uninstall

echo Usage: context-menus.cmd [-a (add) ^| -r (remove)]
exit /b 1

:install
echo Installing Context Menus... ...
set "SCRIPT_PATH=%~dp0bak-zip.cmd"

:: Root cascading menu
REG ADD "HKCU\Software\Classes\Directory\shell\SmartBackupZipCMD" /v "MUIVerb" /t REG_SZ /d "Smart Backup / Zip" /f >nul
REG ADD "HKCU\Software\Classes\Directory\shell\SmartBackupZipCMD" /v "SubCommands" /t REG_SZ /d "" /f >nul

:: 1. Backup Folder
REG ADD "HKCU\Software\Classes\Directory\shell\SmartBackupZipCMD\shell\01Backup" /v "MUIVerb" /t REG_SZ /d "Backup (Timestamped)" /f >nul
REG ADD "HKCU\Software\Classes\Directory\shell\SmartBackupZipCMD\shell\01Backup\command" /ve /t REG_SZ /d "\"%SCRIPT_PATH%\" \"%%1\"" /f >nul

:: 2. Zip Folder
REG ADD "HKCU\Software\Classes\Directory\shell\SmartBackupZipCMD\shell\02Zip" /v "MUIVerb" /t REG_SZ /d "Zip (Timestamped)" /f >nul
REG ADD "HKCU\Software\Classes\Directory\shell\SmartBackupZipCMD\shell\02Zip\command" /ve /t REG_SZ /d "\"%SCRIPT_PATH%\" -z \"%%1\"" /f >nul

:: 3. Settings
REG ADD "HKCU\Software\Classes\Directory\shell\SmartBackupZipCMD\shell\03Settings" /v "MUIVerb" /t REG_SZ /d "Open Settings" /f >nul
REG ADD "HKCU\Software\Classes\Directory\shell\SmartBackupZipCMD\shell\03Settings" /v "CommandFlags" /t REG_DWORD /d 32 /f >nul
REG ADD "HKCU\Software\Classes\Directory\shell\SmartBackupZipCMD\shell\03Settings\command" /ve /t REG_SZ /d "\"%SCRIPT_PATH%\" -c" /f >nul

echo Context Menus Successfully Installed!
exit /b 0

:uninstall
echo Removing Context Menus... ...
REG DELETE "HKCU\Software\Classes\Directory\shell\SmartBackupZipCMD" /f >nul 2>&1
echo Context Menus Successfully Removed!
exit /b 0