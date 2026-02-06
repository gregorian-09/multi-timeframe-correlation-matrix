@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "SCRIPT_DIR=%~dp0"
set "MT5_PATH="
set "MQL5_PATH="
set "LOG_FILE="

call :find_mt5_path
if not defined MT5_PATH (
  echo.
  echo MetaTrader 5 not found in common locations.
  set /p MT5_PATH=Enter MT5 installation path: 
)

if not defined MT5_PATH (
  echo Installation aborted.
  exit /b 1
)

if not exist "%MT5_PATH%" (
  echo Invalid MT5 path: %MT5_PATH%
  exit /b 1
)

call :find_mql5_path
if not defined MQL5_PATH (
  echo Failed to locate MQL5 data folder.
  exit /b 1
)

for /f %%T in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set "STAMP=%%T"
set "LOG_FILE=%SCRIPT_DIR%install_%STAMP%.log"
echo Install started: %DATE% %TIME% > "%LOG_FILE%"
echo MT5_PATH=%MT5_PATH% >> "%LOG_FILE%"
echo MQL5_PATH=%MQL5_PATH% >> "%LOG_FILE%"

echo.
call :make_backup

echo.
echo Copying files to: %MQL5_PATH%
echo Copying files to: %MQL5_PATH% >> "%LOG_FILE%"
call :copy_files

call :compile_indicator

echo.
echo Installation complete.
echo Installation complete. >> "%LOG_FILE%"
exit /b 0

:find_mt5_path
set "CANDIDATES=C:\Program Files\MetaTrader 5 C:\Program Files (x86)\MetaTrader 5 D:\Program Files\MetaTrader 5 C:\MT5"
for %%P in (%CANDIDATES%) do (
  if exist "%%P\terminal64.exe" (
    set "MT5_PATH=%%P"
    goto :eof
  )
)

for %%P in (%CANDIDATES%) do (
  if exist "%%P\terminal.exe" (
    set "MT5_PATH=%%P"
    goto :eof
  )
)

goto :eof

:find_mql5_path
if exist "%MT5_PATH%\MQL5" (
  set "MQL5_PATH=%MT5_PATH%\MQL5"
  goto :eof
)

set "COUNT=0"
for /d %%D in ("%APPDATA%\MetaQuotes\Terminal\*") do (
  if exist "%%D\MQL5" (
    set "ORIGIN="
    if exist "%%D\origin.txt" (
      for /f "usebackq delims=" %%O in ("%%D\origin.txt") do set "ORIGIN=%%O"
      if defined ORIGIN (
        set "ORIGIN=!ORIGIN:"=!"
      )
    )
    set /a COUNT+=1
    set "DATA!COUNT!=%%D\MQL5"
    set "ORIGIN!COUNT!=!ORIGIN!"
  )
)

if "%COUNT%"=="0" goto :eof
if "%COUNT%"=="1" (
  set "MQL5_PATH=!DATA1!"
  goto :eof
)

for /l %%I in (1,1,%COUNT%) do (
  if /I "!ORIGIN%%I!"=="%MT5_PATH%" (
    set "MQL5_PATH=!DATA%%I!"
    goto :eof
  )
)

echo.
echo Multiple MT5 data folders found:
for /l %%I in (1,1,%COUNT%) do (
  if defined ORIGIN%%I (
    echo [%%I] !DATA%%I! ^(origin: !ORIGIN%%I!^)
  ) else (
    echo [%%I] !DATA%%I!
  )
)
set /p SEL=Select data folder index: 
if not defined SEL goto :eof
set "MQL5_PATH=!DATA%SEL%!"

goto :eof

:make_backup
set "BACKUP_DIR=%SCRIPT_DIR%backup_%STAMP%"
mkdir "%BACKUP_DIR%" >nul 2>&1
echo Backup folder: %BACKUP_DIR% >> "%LOG_FILE%"

call :backup_if_exists "%MQL5_PATH%\Include\CorrelationEngine.mqh"
call :backup_if_exists "%MQL5_PATH%\Include\MatrixDisplay.mqh"
call :backup_if_exists "%MQL5_PATH%\Include\DataManager.mqh"
call :backup_if_exists "%MQL5_PATH%\Include\AlertManager.mqh"
call :backup_if_exists "%MQL5_PATH%\Indicators\MultiTimeframeCorrelation.mq5"
call :backup_if_exists "%MQL5_PATH%\Indicators\MultiTimeframeCorrelation.ex5"
call :backup_if_exists "%MQL5_PATH%\Scripts\ExportCorrelations.mq5"
call :backup_if_exists "%MQL5_PATH%\Scripts\CorrelationBacktest.mq5"
call :backup_if_exists "%MQL5_PATH%\Presets\config_forex_majors.set"
call :backup_if_exists "%MQL5_PATH%\Presets\config_indices.set"
call :backup_if_exists "%MQL5_PATH%\Presets\config_commodities.set"
call :backup_if_exists "%MQL5_PATH%\Presets\config_crypto.set"

goto :eof

:backup_if_exists
if exist "%~1" (
  echo Backing up %~nx1
  echo Backing up %~1 >> "%LOG_FILE%"
  copy "%~1" "%BACKUP_DIR%" >nul
)
exit /b 0

:copy_files
if exist "%SCRIPT_DIR%Include" (
  xcopy /y /q "%SCRIPT_DIR%Include\*.mqh" "%MQL5_PATH%\Include\" >nul
  echo Copied Include\*.mqh >> "%LOG_FILE%"
)
if exist "%SCRIPT_DIR%Indicators" (
  xcopy /y /q "%SCRIPT_DIR%Indicators\*.mq5" "%MQL5_PATH%\Indicators\" >nul
  echo Copied Indicators\*.mq5 >> "%LOG_FILE%"
)
if exist "%SCRIPT_DIR%Scripts" (
  xcopy /y /q "%SCRIPT_DIR%Scripts\*.mq5" "%MQL5_PATH%\Scripts\" >nul
  echo Copied Scripts\*.mq5 >> "%LOG_FILE%"
)
if exist "%SCRIPT_DIR%Examples" (
  xcopy /y /q "%SCRIPT_DIR%Examples\*.set" "%MQL5_PATH%\Presets\" >nul
  echo Copied Examples\*.set >> "%LOG_FILE%"
)

goto :eof

:compile_indicator
set "ME=%MT5_PATH%\metaeditor64.exe"
if not exist "%ME%" set "ME=%MT5_PATH%\metaeditor.exe"

if exist "%ME%" (
  echo.
  echo Compiling indicator...
  "%ME%" /compile:"%MQL5_PATH%\Indicators\MultiTimeframeCorrelation.mq5" /log
  echo Compiled via MetaEditor. >> "%LOG_FILE%"
) else (
  echo MetaEditor not found. Skipping compilation.
  echo MetaEditor not found. Skipping compilation. >> "%LOG_FILE%"
)

goto :eof
