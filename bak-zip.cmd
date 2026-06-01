@echo off
setlocal EnableDelayedExpansion

set "VERSION=1.0.0-cmd"
set "CONFIG_DIR=%~dp0"
:: Strip trailing slash if present
if "%CONFIG_DIR:~-1%"=="\" set "CONFIG_DIR=%CONFIG_DIR:~0,-1%"
set "CONFIG_FILE=%CONFIG_DIR%\bak-zip.cfg"

:: Defaults
set "SMART_TARGET=.\_backup"
set "BACKUP_TARGET="
set "ZIP_TARGET="
set "EXCLUDE_FOLDERS_AND_FILES_IN_DOT_GITIGNORE=true"
set "PAUSE_ON_ERROR=true"
set "EXCLUDES=.git, node_modules, dist, build, .vscode*, *-lock.json, _backup*"

set "IS_ZIP=false"
set "OVERRIDE_TARGET="
set "TARGET_PATH=."

:: Parse Arguments
:argLoop
if "%~1"=="" goto argDone
if /I "%~1"=="-h" goto showHelp
if /I "%~1"=="--help" goto showHelp
if /I "%~1"=="-v" (echo backup-zip v%VERSION% [CMD] & exit /b 0)
if /I "%~1"=="-c" goto openConfig
if /I "%~1"=="-z" (set "IS_ZIP=true" & shift & goto argLoop)
if /I "%~1"=="-t" (set "OVERRIDE_TARGET=%~2" & shift & shift & goto argLoop)
:: Catch all for path
set "TARGET_PATH=%~1"
shift
goto argLoop
:argDone

goto :loadConfig

:showHelp
echo backup-zip v%VERSION% [CMD]
echo.
echo Usage:
echo   bkdir [path] [-t target] [-z]
echo   zpdir [path] [-t target]
echo.
echo Options:
echo   -t       Override destination folder
echo   -z       Compress into archive
echo   -c       Open config file
echo   -h       Show help
exit /b 0

:openConfig
if not exist "%CONFIG_FILE%" (
    echo SMART_TARGET=.\_backup> "%CONFIG_FILE%"
    echo BACKUP_TARGET=>> "%CONFIG_FILE%"
    echo ZIP_TARGET=>> "%CONFIG_FILE%"
    echo EXCLUDES=.git, node_modules, dist, build, .vscode*, *-lock.json, _backup*, .DS_Store>> "%CONFIG_FILE%"
    echo EXCLUDE_FOLDERS_AND_FILES_IN_DOT_GITIGNORE=true>> "%CONFIG_FILE%"
    echo PAUSE_ON_ERROR=true>> "%CONFIG_FILE%"
)
start notepad "%CONFIG_FILE%"
exit /b 0

:loadConfig
if not exist "%CONFIG_FILE%" call :openConfig

for /f "usebackq tokens=1,* delims==" %%A in ("%CONFIG_FILE%") do (
    set "key=%%A"
    set "val=%%B"
    if not "!key!"=="" if not "!key:~0,1!"=="#" (
        :: Trim trailing spaces safely
        for /l %%I in (1,1,31) do if "!key:~-1!"==" " set "key=!key:~0,-1!"
        if /I "!key!"=="SMART_TARGET" set "SMART_TARGET=!val!"
        if /I "!key!"=="BACKUP_TARGET" set "BACKUP_TARGET=!val!"
        if /I "!key!"=="ZIP_TARGET" set "ZIP_TARGET=!val!"
        if /I "!key!"=="PAUSE_ON_ERROR" set "PAUSE_ON_ERROR=!val!"
        if /I "!key!"=="EXCLUDE_FOLDERS_AND_FILES_IN_DOT_GITIGNORE" set "EXCLUDE_FOLDERS_AND_FILES_IN_DOT_GITIGNORE=!val!"
        if /I "!key!"=="EXCLUDES" set "EXCLUDES=!val!"
    )
)

:: Resolve Source Absolute Path
pushd "%TARGET_PATH%" 2>nul
if errorlevel 1 (
    echo [ERROR] Source folder does not exist: %TARGET_PATH%
    goto :die
)
set "SRC_ABS=%CD%"
popd
for %%I in ("%SRC_ABS%") do set "SRC_NAME=%%~nxI"
for %%I in ("%SRC_ABS%") do set "SRC_PARENT=%%~dpI"
set "SRC_PARENT=%SRC_PARENT:~0,-1%"

if "%SRC_ABS:~-2%"==":\" (
    echo [ERROR] Cannot backup a root drive directly for safety reasons.
    goto :die
)

:: Resolve Destination Root
set "DEST_ROOT="
if not "%OVERRIDE_TARGET%"=="" (
    echo %OVERRIDE_TARGET%| findstr /r "^[a-zA-Z]:\\" >nul
    if not errorlevel 1 (
        set "DEST_ROOT=%OVERRIDE_TARGET%"
    ) else (
        set "DEST_ROOT=%CD%\%OVERRIDE_TARGET%"
    )
) else if not "%SMART_TARGET%"=="" (
    set "SMART_PATH=%SRC_PARENT%\%SMART_TARGET:.\=%"
    if exist "!SMART_PATH!\" set "DEST_ROOT=!SMART_PATH!"
)

if "!DEST_ROOT!"=="" (
    set "DED_TARGET=%BACKUP_TARGET%"
    if "%IS_ZIP%"=="true" if not "%ZIP_TARGET%"=="" set "DED_TARGET=%ZIP_TARGET%"

    if not "!DED_TARGET!"=="" (
        echo !DED_TARGET!| findstr /r "^[a-zA-Z]:\\" >nul
        if not errorlevel 1 (
            set "DEST_ROOT=!DED_TARGET!"
        ) else (
            set "DEST_ROOT=%SRC_PARENT%\!DED_TARGET:.\=%"
        )
        if not exist "!DEST_ROOT!\" mkdir "!DEST_ROOT!"
    ) else (
        set "DEST_ROOT=%SRC_PARENT%"
    )
)

:: Normalize DEST_ROOT
if "%DEST_ROOT:~-1%"=="\" set "DEST_ROOT=%DEST_ROOT:~0,-1%"

:: Bulletproof Timestamp via PS
for /f %%A in ('powershell -NoProfile -Command "Get-Date -Format 'yyyyMMdd-HHmmss'"') do set "TIMESTAMP=%%A"

set "BAK_NAME=%SRC_NAME%-%TIMESTAMP%"
set "BAK_DIR=%DEST_ROOT%\%BAK_NAME%"

if exist "%BAK_DIR%" (
    set "BAK_NAME=%BAK_NAME%-%RANDOM%"
    set "BAK_DIR=%DEST_ROOT%\!BAK_NAME!"
)

echo [INFO] Source: %SRC_ABS%
echo [INFO] Target: %BAK_DIR%
mkdir "%BAK_DIR%"

:: Build Exclusions array for Robocopy
set "ROBO_EXCLUDES="

:: Parse config exclusions
if not "!EXCLUDES!"=="" (
    set "ROBO_EXCLUDES=!EXCLUDES:,= !"
)

:: Parse .gitignore
if /I "%EXCLUDE_FOLDERS_AND_FILES_IN_DOT_GITIGNORE%"=="true" (
    if exist "%SRC_ABS%\.gitignore" (
        for /f "usebackq eol=# tokens=*" %%L in ("%SRC_ABS%\.gitignore") do (
            set "line=%%L"
            if "!line:~0,1!"=="/" set "line=!line:~1!"
            if "!line:~-1!"=="/" set "line=!line:~0,-1!"
            if not "!line!"=="" set "ROBO_EXCLUDES=!ROBO_EXCLUDES! !line!"
        )
    )
)

:: Execute Robocopy
set "ROBO_ARGS=/E /MT:8 /NFL /NDL /NJH /NJS"
if not "%ROBO_EXCLUDES%"=="" (
    set "ROBO_ARGS=!ROBO_ARGS! /XD %ROBO_EXCLUDES% /XF %ROBO_EXCLUDES%"
)

robocopy "%SRC_ABS%" "%BAK_DIR%" %ROBO_ARGS% >nul
set "RC=%ERRORLEVEL%"

:: Robocopy exit codes < 8 are successes.
if %RC% GEQ 8 (
    echo [ERROR] Robocopy failed with exit code %RC%.
    goto :die
)

if "%IS_ZIP%"=="true" (
    echo [INFO] Compressing backup natively...
    set "ZIP_NAME=%BAK_NAME%.zip"

    pushd "%DEST_ROOT%"
    tar.exe -a -c -f "!ZIP_NAME!" "%BAK_NAME%"
    set "ZIP_RC=!ERRORLEVEL!"
    popd

    if !ZIP_RC! EQU 0 (
        rmdir /s /q "%BAK_DIR%"
        echo [SUCCESS] Zipped to: %DEST_ROOT%\!ZIP_NAME!
    ) else (
        echo [ERROR] Compression failed. Unzipped folder retained.
        goto :die
    )
) else (
    echo [SUCCESS] Backup created at: %BAK_DIR%
)

:: Removed the pause here so it exits completely seamlessly on success!
exit /b 0

:die
if "%PAUSE_ON_ERROR%"=="true" pause
exit /b 1