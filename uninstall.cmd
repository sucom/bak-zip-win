@echo off
setlocal EnableDelayedExpansion

echo Starting Uninstallation...

set "INSTALL_DIR=%USERPROFILE%\bak-zip-cmd"

if exist "%INSTALL_DIR%\context-menus.cmd" (
    echo Removing Context Menus...
    call "%INSTALL_DIR%\context-menus.cmd" -r
)

echo Removing from User PATH...
:: Safely strips only this specific path directory out of the environment variable
powershell -NoProfile -Command "$p = [Environment]::GetEnvironmentVariable('PATH', 'User'); $clean = ($p -split ';' | Where-Object { $_ -ne '%INSTALL_DIR%' -and $_ -ne '' }) -join ';'; [Environment]::SetEnvironmentVariable('PATH', $clean, 'User');"

echo Deleting Installation Directory...
if exist "%INSTALL_DIR%" rmdir /s /q "%INSTALL_DIR%"

echo.
echo [SUCCESS] Uninstallation Complete! Your system is clean.
exit /b 0