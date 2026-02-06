# Troubleshooting

## 1. Indicator Does Not Load

Check:

- `MultiTimeframeCorrelation.mq5` compiles cleanly
- include files exist in `MQL5\Include\`
- Navigator refreshed or MT5 restarted

## 2. Matrix Panels Missing or Partial

Check:

- `InpXPosition`, `InpYPosition`, `InpCellSize`
- symbol count vs panel size
- chart object limits (reduce symbols/timeframes)

## 3. Data Issues (`EMPTY_VALUE`, blank cells)

Likely causes:

- insufficient history for symbol/timeframe
- symbol not enabled in Market Watch
- weekend/market-closed flat data

Actions:

- lower lookback bars
- switch to active timeframe/symbol
- verify symbol naming on broker

## 4. Refresh Actions Not Working

- Press `R` for forced refresh.
- Ensure `InpEnableRightClickRefresh=true` for right-click refresh.
- Resize/switch chart to trigger chart-change refresh.

## 5. Alerts Not Triggering

Check:

- push/email/sound settings in MT5 terminal options
- `InpAlertCooldown` not too high
- thresholds not too strict (`InpDivergenceThreshold`, `InpThresholdLevel`, etc.)

## 6. Export Failures

For script and indicator exports:

- verify write access to `MQL5\Files\`
- check filename/prefix validity
- inspect Experts/Journal logs for `FileOpen` errors

## 7. Logging Not Visible

Set `InpLogLevel`:

- `LOG_OFF`: no logs
- `LOG_ERROR`: failures only
- `LOG_DEBUG`: detailed diagnostics

Look in:

- `Toolbox > Experts`
- `Toolbox > Journal`

## 8. Performance Degradation

- reduce symbols
- reduce timeframes
- increase update interval
- close heavy indicators/charts

## 9. Common Runtime Error Sources

- `CopyClose`/`CopyTime` failures from unavailable data
- chart object overload with very large matrices
- SMTP/push misconfiguration for notifications

## 10. Validation Checklist (Windows/MT5)

1. Compile indicator and scripts.
2. Run tests:
- `Tests/test_correlation.mq5`
- `Tests/test_correlation_edge_cases.mq5`
- `Tests/test_data_manager.mq5`
3. Verify:
- hotkeys (`R`, `V`, `E`)
- right-click refresh
- CSV exports
- expected alert behavior
