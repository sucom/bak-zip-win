@echo off
setlocal EnableDelayedExpansion

echo Starting Installation...

set "INSTALL_DIR=%USERPROFILE%\bak-zip-cmd"
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

echo Copying files to %INSTALL_DIR%...
copy /y "%~dp0bak-zip.cfg" "%INSTALL_DIR%\" >nul
copy /y "%~dp0bak-zip.cmd" "%INSTALL_DIR%\" >nul
copy /y "%~dp0bkdir.cmd" "%INSTALL_DIR%\" >nul
copy /y "%~dp0zpdir.cmd" "%INSTALL_DIR%\" >nul
copy /y "%~dp0bkdir" "%INSTALL_DIR%\" >nul
copy /y "%~dp0zpdir" "%INSTALL_DIR%\" >nul
copy /y "%~dp0context-menus.cmd" "%INSTALL_DIR%\" >nul

echo Installing Context Menus...
call "%INSTALL_DIR%\context-menus.cmd" -a

echo Injecting into User PATH...
:: We use PowerShell to safely manage the PATH length limit that setx fails on
powershell -NoProfile -Command "$p = [Environment]::GetEnvironmentVariable('PATH', 'User'); if ($p -notlike '*%INSTALL_DIR%*') { $newPath = $p + ';%INSTALL_DIR%'; [Environment]::SetEnvironmentVariable('PATH', $newPath, 'User'); Write-Host 'Added to PATH.' } else { Write-Host 'Already in PATH.' }"

echo.
echo [SUCCESS] Installation Complete!
echo Please restart your terminal to use 'bkdir' and 'zpdir' globally.
exit /b 0