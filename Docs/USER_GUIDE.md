# User Guide

## Quick Start

1. Open chart in MT5.
2. Add `MultiTimeframeCorrelation` from custom indicators.
3. Set symbols and timeframes.
4. Confirm panels render (one panel per timeframe).

## Core Inputs

### Data

- `Symbols`: comma-separated symbol list
- `Timeframes`: comma-separated timeframe list
- `InpLookbackBars`: bars used for correlation math
- `InpUpdateInterval`: timer refresh cadence (seconds)

### Display

- `InpXPosition`, `InpYPosition`, `InpCellSize`
- `InpPositiveColor`, `InpNegativeColor`, `InpNeutralColor`
- `InpUseColorBlindPalette`
- `InpEnableCellTooltips`

### Interactions

- `InpEnableRightClickRefresh`

Hotkeys:

- `R`: force refresh
- `V`: toggle panel visibility
- `E`: export in-memory history CSV

### Alerts

- `InpEnablePush`, `InpEnableEmail`, `InpEnableSound`
- `InpDivergenceThreshold`
- `InpAlertCooldown`
- `InpRecentWindow`, `InpHistoricalWindow`
- `InpThresholdLevel`, `InpStrongLevel`, `InpBreakdownDrop`, `InpRecoveryBand`

### History / Export / Telemetry

- `InpStoredHistoryLimit`
- `InpStabilityWindow`
- `InpExportHistoryOnDeinit`
- `InpHistoryExportPrefix`
- `InpLogLevel` (`LOG_OFF`, `LOG_ERROR`, `LOG_DEBUG`)

## Reading the Matrix

- Diagonal cells are always `1.00`.
- Matrix is symmetric.
- Color bands:
  - strong positive (green)
  - moderate positive
  - weak/neutral
  - moderate negative
  - strong negative (red)

## Exports

### Script Export

Run `Scripts/ExportCorrelations.mq5` to generate:

- current matrix CSV per timeframe
- optional historical CSV with rolling mean/stddev

### In-Indicator Export

Press `E` to export in-memory tracked history:

- file pattern: `correlation_history_<date>.csv` (or custom prefix)

## Operational Logging

- `LOG_OFF`: no logger output
- `LOG_ERROR`: only failures
- `LOG_DEBUG`: failures + progress diagnostics

Use `LOG_DEBUG` for troubleshooting sessions only.
