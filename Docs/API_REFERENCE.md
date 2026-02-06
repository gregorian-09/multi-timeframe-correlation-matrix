# API Reference

## Conventions

- Invalid numeric outputs use `EMPTY_VALUE`.
- Retrieval failures return `-1` or `false`.
- Logger output is controlled by `ENUM_LOG_LEVEL`.

## `CCorrelationEngine` (`Include/CorrelationEngine.mqh`)

### Methods

```cpp
bool Initialize(int lookbackBars, double divergenceThreshold)
int GetLookbackBars() const
double GetDivergenceThreshold() const
double CalculateCorrelation(const double &prices1[], const double &prices2[], int count)
ENUM_CORRELATION_STRENGTH GetCorrelationStrength(double value)
bool DetectDivergence(double historicalCorr, double currentCorr) const
bool DetectDivergence(const string symbol1, const string symbol2, double historicalCorr, double currentCorr) const
bool BuildMatrix(double &matrix[][], const string &symbols[], ENUM_TIMEFRAMES timeframe, CDataManager &data, int bars)
bool BuildMatrix(double &matrix[][], const string &symbols[], ENUM_TIMEFRAMES timeframe, CDataManager &data)
bool BuildMatrix(double &matrix[][], const string &symbols[], ENUM_TIMEFRAMES timeframe)
```

## `CDataManager` (`Include/DataManager.mqh`)

### Methods

```cpp
bool Initialize(const string symbolsCsv, const string timeframesCsv, int cacheSeconds = 60)
bool ParseSymbols(const string symbolsCsv)
int ParseSymbols(const string input, string &result[])
bool ParseTimeframes(const string timeframesCsv)
int ParseTimeframes(const string input, ENUM_TIMEFRAMES &result[])
void GetSymbols(string &outSymbols[]) const
void GetTimeframes(ENUM_TIMEFRAMES &outTimeframes[]) const
int GetPriceData(const string symbol, ENUM_TIMEFRAMES tf, int bars, double &outPrices[])
int GetSymbolCount() const
int GetTimeframeCount() const
void RefreshCache()
void Cleanup()
```

## `CMatrixDisplay` (`Include/MatrixDisplay.mqh`)

### Methods

```cpp
bool Initialize(int xPos, int yPos, int cellSize, color positiveColor, color negativeColor, color neutralColor, const string prefix = CORRELATION_PREFIX)
color GetColorForValue(double correlation)
void DrawLegend()
void DrawTitle(const string text)
string GetTitleObjectName() const
bool IsVisible() const
void SetTitle(const string text)
void SetTooltipsEnabled(bool enabled)
void DrawHeatmap(const double &matrix[][], const string &symbols[])
void SetVisibility(bool visible)
void UpdateCell(int row, int col, double value)
void Clear()
```

## `CAlertManager` (`Include/AlertManager.mqh`)

### Methods

```cpp
bool Initialize(bool enablePush, bool enableEmail, bool enableSound, int cooldownSeconds)
void SetAlertCooldown(int seconds)
void SetCooldown(int seconds)
bool CheckAlertCondition(const string symbol1, const string symbol2, double oldCorr, double newCorr, double threshold) const
bool IsCoolingDown(const string alertKey) const
bool SendAlert(const string message, ENUM_ALERT_TYPE type, const string key)
bool SendAlert(const string message, ENUM_ALERT_TYPE type)
void Cleanup()
```

## `CLogger` (`Include/Logger.mqh`)

### Methods

```cpp
void SetLevel(ENUM_LOG_LEVEL level)
ENUM_LOG_LEVEL GetLevel() const
void Error(const string message) const
void Debug(const string message) const
```

## Enums

```cpp
enum ENUM_CORRELATION_STRENGTH {
  CORR_STRONG_POSITIVE,
  CORR_MODERATE_POSITIVE,
  CORR_WEAK,
  CORR_MODERATE_NEGATIVE,
  CORR_STRONG_NEGATIVE
};

enum ENUM_ALERT_TYPE {
  ALERT_DIVERGENCE,
  ALERT_THRESHOLD,
  ALERT_RECOVERY,
  ALERT_BREAKDOWN
};

enum ENUM_LOG_LEVEL {
  LOG_OFF,
  LOG_ERROR,
  LOG_DEBUG
};
```

## Constants (`Include/Constants.mqh`)

```cpp
CORRELATION_PREFIX
MAX_SYMBOLS
MAX_TIMEFRAMES
DEFAULT_LOOKBACK
DEFAULT_CELL_SIZE
DEFAULT_COOLDOWN
DEFAULT_CACHE_SECONDS
```
