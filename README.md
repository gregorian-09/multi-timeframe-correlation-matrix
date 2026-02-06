# Multi-Timeframe Correlation Matrix Dashboard

Open-source MQL5 indicator for real-time, multi-timeframe correlation analysis across symbols.

## Features

- Multi-symbol Pearson correlation matrix
- Multi-timeframe stacked panels (M1 to MN1)
- Heatmap visualization with incremental updates
- Hover tooltips with exact correlation values
- Divergence, threshold, breakdown, and recovery alerts
- In-memory historical tracking with CSV export
- Color-blind palette option
- Runtime telemetry controls (`LOG_OFF`, `LOG_ERROR`, `LOG_DEBUG`)

## Project Layout

- `Include/` core modules (`CorrelationEngine`, `DataManager`, `MatrixDisplay`, `AlertManager`, `Logger`, constants)
- `Indicators/MultiTimeframeCorrelation.mq5` main indicator
- `Scripts/` export/backtest scripts
- `Tests/` script-based tests
- `Docs/` user/developer docs
- `Docs/` in-depth architecture, API, UML, structure, and contributor docs

## Installation

### Automated (Windows)

1. Run `install.bat` as Administrator.
2. Restart MetaTrader 5.
3. Add `MultiTimeframeCorrelation` to a chart.

### Manual

See `Docs/INSTALLATION.md`.

## Usage

1. Add indicator: `Insert > Indicators > Custom > MultiTimeframeCorrelation`.
2. Configure symbols/timeframes and alert/display options.
3. Interactions:
- `R` force refresh
- `V` toggle visibility
- `E` export in-memory history CSV
- right-click refresh (if enabled)

## Tests

Run in MT5/MetaEditor:

- `Tests/test_correlation.mq5`
- `Tests/test_correlation_edge_cases.mq5`
- `Tests/test_data_manager.mq5`

## Documentation

- Quick docs: `Docs/`
- Contributor deep docs: `Docs/DEEP_DOCS_OVERVIEW.md`

## License

MIT. See `LICENSE`.
