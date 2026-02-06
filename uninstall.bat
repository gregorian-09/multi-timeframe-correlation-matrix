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
  echo Uninstall aborted.
  exit /b 1
)

set "MT5_PATH=%MT5_PATH:"=%"
if "%MT5_PATH:~-1%"=="\" set "MT5_PATH=%MT5_PATH:~0,-1%"

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
set "LOG_FILE=%SCRIPT_DIR%uninstall_%STAMP%.log"
echo Uninstall started: %DATE% %TIME% > "%LOG_FILE%"
echo MT5_PATH=%MT5_PATH% >> "%LOG_FILE%"
echo MQL5_PATH=%MQL5_PATH% >> "%LOG_FILE%"

echo.
echo The following files will be removed:
echo %MQL5_PATH%\Include\CorrelationEngine.mqh
echo %MQL5_PATH%\Include\MatrixDisplay.mqh
echo %MQL5_PATH%\Include\DataManager.mqh
echo %MQL5_PATH%\Include\AlertManager.mqh
echo %MQL5_PATH%\Include\Constants.mqh
echo %MQL5_PATH%\Indicators\MultiTimeframeCorrelation.mq5
echo %MQL5_PATH%\Indicators\MultiTimeframeCorrelation.ex5
echo %MQL5_PATH%\Scripts\ExportCorrelations.mq5
echo %MQL5_PATH%\Scripts\CorrelationBacktest.mq5
echo %MQL5_PATH%\Presets\config_forex_majors.set
echo %MQL5_PATH%\Presets\config_indices.set
echo %MQL5_PATH%\Presets\config_commodities.set
echo %MQL5_PATH%\Presets\config_crypto.set

echo.
set /p CONFIRM=Continue? (y/N): 
if /I not "%CONFIRM%"=="y" (
  echo Uninstall cancelled.
  echo Uninstall cancelled. >> "%LOG_FILE%"
  exit /b 0
)

call :del_if_exists "%MQL5_PATH%\Include\CorrelationEngine.mqh"
call :del_if_exists "%MQL5_PATH%\Include\MatrixDisplay.mqh"
call :del_if_exists "%MQL5_PATH%\Include\DataManager.mqh"
call :del_if_exists "%MQL5_PATH%\Include\AlertManager.mqh"
call :del_if_exists "%MQL5_PATH%\Include\Constants.mqh"
call :del_if_exists "%MQL5_PATH%\Indicators\MultiTimeframeCorrelation.mq5"
call :del_if_exists "%MQL5_PATH%\Indicators\MultiTimeframeCorrelation.ex5"
call :del_if_exists "%MQL5_PATH%\Scripts\ExportCorrelations.mq5"
call :del_if_exists "%MQL5_PATH%\Scripts\CorrelationBacktest.mq5"
call :del_if_exists "%MQL5_PATH%\Presets\config_forex_majors.set"
call :del_if_exists "%MQL5_PATH%\Presets\config_indices.set"
call :del_if_exists "%MQL5_PATH%\Presets\config_commodities.set"
call :del_if_exists "%MQL5_PATH%\Presets\config_crypto.set"

echo.
echo Uninstall complete.
echo Uninstall complete. >> "%LOG_FILE%"
exit /b 0

:find_mt5_path
for %%P in ("C:\Program Files\MetaTrader 5" "C:\Program Files (x86)\MetaTrader 5" "D:\Program Files\MetaTrader 5" "C:\MT5") do (
  if exist "%%P\terminal64.exe" (
    set "MT5_PATH=%%P"
    goto :eof
  )
)

for %%P in ("C:\Program Files\MetaTrader 5" "C:\Program Files (x86)\MetaTrader 5" "D:\Program Files\MetaTrader 5" "C:\MT5") do (
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
        set "ORIGIN=!ORIGIN:\terminal64.exe=!"
        set "ORIGIN=!ORIGIN:\terminal.exe=!"
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

:del_if_exists
if exist "%~1" (
  del /q "%~1"
  echo Deleted %~1 >> "%LOG_FILE%"
)
exit /b 0
