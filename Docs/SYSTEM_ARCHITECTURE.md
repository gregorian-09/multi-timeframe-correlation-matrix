# 01 System Architecture

## Purpose

The indicator computes and visualizes correlation matrices across multiple symbols and multiple timeframes, then raises alerts when relationship regimes change.

## Runtime Modules

- `Indicators/MultiTimeframeCorrelation.mq5`
- `Include/CorrelationEngine.mqh`
- `Include/DataManager.mqh`
- `Include/MatrixDisplay.mqh`
- `Include/AlertManager.mqh`
- `Include/Logger.mqh`

## Core Runtime Loop

1. `OnInit`
- Sets telemetry level.
- Parses symbols/timeframes.
- Initializes engine, alert manager, and one display panel per timeframe.
- Enables timer and optional right-click mouse tracking.
- Performs an initial full refresh.

2. `OnTimer`
- Triggers `RefreshAllTimeframes(false)`.
- Each timeframe builds matrix, updates panel, evaluates alerts, updates history state.

3. `OnChartEvent`
- `R`: forced refresh (`RefreshAllTimeframes(true)`).
- `V`: toggles panel visibility.
- `E`: exports in-memory correlation history CSV.
- Right-click edge (when enabled): forced refresh.
- Title double-click: toggles panel visibility.

4. `OnDeinit`
- Stops timer and optional mouse event mode.
- Clears display objects.
- Cleans data/alert/history state.
- Optional history export on deinit.

## State Model

### Indicator State

- `g_symbols[]`, `g_timeframes[]`
- `g_displays[MAX_TIMEFRAMES]`
- `g_panels_visible`, `g_right_mouse_down`
- `g_history[]` (pair-timeframe rolling history + alert-state)

### Pair History Entry

- Key identity: `symbol1_symbol2_timeframe`
- Timeseries: `values[]`, `times[]`
- Alert helpers: `has_prev`, `prev_corr`, `breakdown_active`

## Divergence and Regime Logic

For each pair per timeframe:

1. Append latest correlation to bounded history.
2. Compute:
- Recent average (`InpRecentWindow`)
- Historical average (`InpHistoricalWindow`, offset behind recent window)
3. Trigger alerts:
- Divergence: `abs(historical - recent) >= InpDivergenceThreshold`
- Threshold crossing: absolute corr crosses `InpThresholdLevel`
- Breakdown: historically strong relation (`InpStrongLevel`) drops by `InpBreakdownDrop`
- Recovery: current corr returns within `InpRecoveryBand` of historical baseline

## Rendering Strategy

`MatrixDisplay` uses object pooling and incremental updates:

- Pre-allocates cell and label objects per panel size.
- Updates only changed cell values (`m_last_values` cache).
- Optional hover tooltips for each cell.
- Supports per-panel object prefix to isolate timeframe panels.

## Telemetry Model

`Logger.mqh` provides three levels:

- `LOG_OFF`: no logger output
- `LOG_ERROR`: errors only
- `LOG_DEBUG`: errors + operational debug

Applied in indicator and scripts through `InpLogLevel`.

## Failure Handling

Data and file I/O paths log contextual diagnostics:

- `CopyClose`/`CopyTime` failures include symbol/timeframe/requested/copy/error.
- `FileOpen` failures include target path and error code.
- Cache freshness check falls back to forced refresh path when `CopyTime` fails.
