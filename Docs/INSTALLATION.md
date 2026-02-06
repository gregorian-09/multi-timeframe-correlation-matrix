# Installation Guide

## Requirements

- MetaTrader 5 (build 3000+)
- Windows 10/11 recommended
- Write access to MT5 data folder

## Automated Install (Recommended)

1. Run `install.bat` as Administrator.
2. Confirm detected MT5 path.
3. Wait for copy/compile steps to finish.
4. Restart MT5.

Installer deploys:

- `Include/*.mqh` -> `MQL5\Include\`
- `Indicators/*.mq5` -> `MQL5\Indicators\`
- `Scripts/*.mq5` -> `MQL5\Scripts\`
- `Examples/*.set` -> `MQL5\Presets\`

## Manual Install

1. Open MT5 -> `File > Open Data Folder`.
2. Copy files to the matching `MQL5` subfolders above.
3. Open MetaEditor (`F4`).
4. Compile `MQL5\Indicators\MultiTimeframeCorrelation.mq5` (`F7`).
5. Restart or refresh Navigator.

## Verify Installation

- Indicator appears under `Navigator > Indicators > Custom`.
- No compile errors in MetaEditor toolbox.
- On chart attach, matrix panels render for configured timeframes.

## Installed File Structure

```text
MQL5/
├── Include/
│   ├── Constants.mqh
│   ├── Logger.mqh
│   ├── DataManager.mqh
│   ├── CorrelationEngine.mqh
│   ├── MatrixDisplay.mqh
│   └── AlertManager.mqh
├── Indicators/
│   └── MultiTimeframeCorrelation.mq5
├── Scripts/
│   ├── ExportCorrelations.mq5
│   └── CorrelationBacktest.mq5
└── Presets/
    ├── config_forex_majors.set
    ├── config_indices.set
    ├── config_commodities.set
    └── config_crypto.set
```

## Uninstall

- Automated: run `uninstall.bat` as Administrator.
- Manual: remove copied include/indicator/script files and compiled `.ex5` output.

## Notes

- Linux/macOS users can edit code/docs here, but MT5 runtime validation must be done on Windows.
