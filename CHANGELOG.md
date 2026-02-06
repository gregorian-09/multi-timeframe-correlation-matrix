# Changelog

All notable changes to this project are documented in this file.

## [1.1.0] - 2026-02-06

### Added

- Multi-timeframe stacked panel rendering.
- Interactions: `R` refresh, `V` visibility toggle, `E` history export, right-click refresh.
- Advanced alerting: divergence windows, threshold, breakdown, recovery.
- Historical pair tracking with rolling stability metrics and CSV export.
- Color-blind display palette option.
- Cell hover tooltips.
- Incremental/pool-based matrix rendering.
- Runtime telemetry logger with `LOG_OFF`, `LOG_ERROR`, `LOG_DEBUG`.
- Expanded tests:
- `test_correlation_edge_cases.mq5`
- `test_data_manager.mq5`
- `FinalDocs/` deep architecture/API/UML/structure docs and diagram assets.

### Changed

- Docs updated across `Docs/` for new inputs and interactions.
- Export and data-copy failure diagnostics now include detailed context and error codes.

## [1.0.0] - 2026-02-04

### Added

- Core correlation engine and matrix build scaffolding.
- Data manager for parsing and cache-based price retrieval.
- Heatmap display module.
- Alert manager with cooldown.
- Main indicator integration.
- Initial export and backtest scripts.
- Basic correlation test script.
