# 05 Contributor Workflow

## Architectural Invariants

Contributors should preserve these invariants:

1. `RefreshAllTimeframes(...)` remains the single source of truth for full redraw paths.
2. Pair-history updates happen before alert checks that depend on history windows.
3. Display object namespaces stay prefix-isolated per timeframe.
4. Data retrieval failures return safely (`-1`/`EMPTY_VALUE`) and do not crash loops.
5. Logger-level gates all operational telemetry noise.

## Where To Add Features

- Correlation math variants: `Include/CorrelationEngine.mqh`
- New alert semantics: `Indicators/MultiTimeframeCorrelation.mq5` + `Include/AlertManager.mqh`
- New rendering behavior: `Include/MatrixDisplay.mqh`
- Data source/caching policy: `Include/DataManager.mqh`
- Telemetry behavior: `Include/Logger.mqh`

## Extension Patterns

### Add a New Alert Type

1. Extend `ENUM_ALERT_TYPE` in `Include/AlertManager.mqh`.
2. Add message prefix mapping in `SendAlert(...)` switch.
3. Add evaluation block in `CheckAlerts(...)` in indicator.
4. Use alert key suffix for cooldown isolation.

### Add a New Panel Interaction

1. Add input toggle in indicator.
2. Wire event in `OnChartEvent`.
3. Route action through existing entrypoint (`RefreshAllTimeframes`, `SetVisibility`, export, etc).

### Add New Export Fields

1. Update writer headers first.
2. Preserve CSV column order across rows.
3. Log file-open failures with logger at `LOG_ERROR`.

## Testing Strategy

Current tests:

- `Tests/test_correlation.mq5`
- `Tests/test_correlation_edge_cases.mq5`
- `Tests/test_data_manager.mq5`

Recommended contributor test checklist:

1. Compile indicator and scripts in MetaEditor.
2. Run all three test scripts and capture logs.
3. Validate multi-timeframe rendering with 2-3 timeframes and 5+ symbols.
4. Verify `R`, `V`, `E`, right-click refresh behavior.
5. Verify export scripts create files and include expected columns.
6. Verify logging behavior with `LOG_OFF`, `LOG_ERROR`, `LOG_DEBUG`.

## Pull Request Checklist

- Feature is isolated to the smallest relevant module.
- New inputs documented in `Docs/USER_GUIDE.md` and `Docs/API_REFERENCE.md`.
- Failure paths log actionable context at error level.
- No regression to panel prefix isolation.
- No regression to cooldown-based alert spam protection.
- Added/updated test scripts where behavior changed.
