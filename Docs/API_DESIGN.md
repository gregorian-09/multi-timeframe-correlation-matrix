# 02 API Design

## Design Goals

- Keep each module single-purpose.
- Keep contracts explicit and resilient to incomplete market data.
- Return status values (`bool`, counts, `EMPTY_VALUE`) instead of throwing-style control flow.

## Module: `CCorrelationEngine`

### Responsibilities

- Correlation math (Pearson)
- Correlation strength classification
- Matrix construction
- Divergence threshold check

### Key APIs

```cpp
bool Initialize(int lookbackBars, double divergenceThreshold)
double CalculateCorrelation(const double &prices1[], const double &prices2[], int count)
ENUM_CORRELATION_STRENGTH GetCorrelationStrength(double value)
bool DetectDivergence(double historicalCorr, double currentCorr) const
bool BuildMatrix(double &matrix[][], const string &symbols[], ENUM_TIMEFRAMES tf, CDataManager &data, int bars)
bool BuildMatrix(double &matrix[][], const string &symbols[], ENUM_TIMEFRAMES tf, CDataManager &data)
bool BuildMatrix(double &matrix[][], const string &symbols[], ENUM_TIMEFRAMES tf)
```

### Return Conventions

- Correlation math failures: `EMPTY_VALUE`
- Matrix build failures: `false`

## Module: `CDataManager`

### Responsibilities

- Parse symbol/timeframe configuration
- Validate symbols
- Fetch close-price data
- Cache and invalidate data

### Key APIs

```cpp
bool Initialize(const string symbolsCsv, const string timeframesCsv, int cacheSeconds = 60)
bool ParseSymbols(const string symbolsCsv)
int ParseSymbols(const string input, string &result[])
bool ParseTimeframes(const string timeframesCsv)
int ParseTimeframes(const string input, ENUM_TIMEFRAMES &result[])
int GetPriceData(const string symbol, ENUM_TIMEFRAMES tf, int bars, double &outPrices[])
void RefreshCache()
void Cleanup()
```

### Cache Policy

Invalidation if any is true:

- Entry empty (`bar_count <= 0`)
- Cache age exceeds `cacheSeconds`
- New bar detected via `CopyTime`

## Module: `CMatrixDisplay`

### Responsibilities

- Draw panel heatmap with headers and labels
- Track and repaint only changed cells
- Handle panel visibility and tooltips

### Key APIs

```cpp
bool Initialize(int xPos, int yPos, int cellSize, color pos, color neg, color neutral, const string prefix)
void DrawHeatmap(const double &matrix[][], const string &symbols[])
void UpdateCell(int row, int col, double value)
void SetVisibility(bool visible)
void SetTitle(const string text)
void SetTooltipsEnabled(bool enabled)
void Clear()
```

### Object Namespace

Every panel gets unique prefix (`CORR_<idx>_`) to prevent collisions between timeframe panels.

## Module: `CAlertManager`

### Responsibilities

- Send alert notifications
- Enforce cooldown by alert key

### Key APIs

```cpp
bool Initialize(bool enablePush, bool enableEmail, bool enableSound, int cooldownSeconds)
bool CheckAlertCondition(const string s1, const string s2, double oldCorr, double newCorr, double threshold) const
bool SendAlert(const string message, ENUM_ALERT_TYPE type, const string key)
bool SendAlert(const string message, ENUM_ALERT_TYPE type)
bool IsCoolingDown(const string alertKey) const
void SetCooldown(int seconds)
void Cleanup()
```

### Alert Types

```cpp
ALERT_DIVERGENCE
ALERT_THRESHOLD
ALERT_RECOVERY
ALERT_BREAKDOWN
```

## Module: `CLogger`

### Responsibilities

- Runtime telemetry gating

### Key APIs

```cpp
void SetLevel(ENUM_LOG_LEVEL level)
ENUM_LOG_LEVEL GetLevel() const
void Error(const string message) const
void Debug(const string message) const
```

### Levels

```cpp
LOG_OFF
LOG_ERROR
LOG_DEBUG
```

## Indicator Integration API (top-level)

### Inputs with Contributor Impact

- Data/refresh: `InpSymbols`, `InpTimeframes`, `InpLookbackBars`, `InpUpdateInterval`
- UI: `InpCellSize`, color settings, `InpUseColorBlindPalette`, `InpEnableCellTooltips`
- Interactions: `InpEnableRightClickRefresh`
- Alerts: divergence/threshold/breakdown/recovery parameters
- History/export: `InpStoredHistoryLimit`, `InpStabilityWindow`, `InpExportHistoryOnDeinit`, `InpHistoryExportPrefix`
- Telemetry: `InpLogLevel`

### Internal Contracts

- `RefreshAllTimeframes(forceDataRefresh)` is the authoritative refresh entrypoint.
- `CheckAlerts(...)` requires matrix values already computed.
- `UpdateHistory(...)` must be called before alert evaluations that depend on windows.
