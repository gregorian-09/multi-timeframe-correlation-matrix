# Examples

## Preset-Like Input Sets

### Forex Majors

```ini
Symbols=EURUSD,GBPUSD,USDJPY,USDCHF,AUDUSD,USDCAD,NZDUSD
Timeframes=H1,H4,D1
LookbackBars=100
UpdateInterval=60
LogLevel=LOG_ERROR
```

### Indices

```ini
Symbols=US500,US30,USTEC,DE40,UK100,JP225
Timeframes=H1,H4,D1
LookbackBars=100
UpdateInterval=120
LogLevel=LOG_ERROR
```

### Commodities

```ini
Symbols=XAUUSD,XAGUSD,XTIUSD,XBRUSD,XNGUSD
Timeframes=H4,D1,W1
LookbackBars=100
UpdateInterval=300
LogLevel=LOG_ERROR
```

### Crypto

```ini
Symbols=BTCUSD,ETHUSD,LTCUSD,XRPUSD,BNBUSD
Timeframes=H1,H4,D1
LookbackBars=50
UpdateInterval=30
LogLevel=LOG_ERROR
```

## Script Usage Examples

### Export Current + Historical

Use `Scripts/ExportCorrelations.mq5` with:

- `InpExportHistorical=true`
- `InpHistoryBars=500`
- `InpHistoryStep=5`
- `InpStabilityWindow=20`

Outputs per timeframe:

- current matrix CSV
- historical rolling stats CSV (`*_history_*`)

### Backtest Rolling Correlations

Use `Scripts/CorrelationBacktest.mq5` for historical windowed correlation rows:

- choose one timeframe
- choose lookback/history bars
- choose step size

## Programmatic Pattern

```cpp
CDataManager data;
CCorrelationEngine engine;

data.Initialize("EURUSD,GBPUSD,USDJPY", "H1,H4", 60);
engine.Initialize(100, 0.3);

string symbols[];
data.GetSymbols(symbols);

double matrix[][];
engine.BuildMatrix(matrix, symbols, PERIOD_H1, data);
```

## Operational Tips

- Keep symbol count under 10 for lower CPU.
- Increase update interval for weaker hardware.
- Use `LOG_DEBUG` only during troubleshooting.
