# Milestones

## Milestone 1: Foundation (Core Math + Tests)
Scope:
- Implement correlation math with deterministic behavior.
- Add unit-test-style script to validate known inputs.
- Establish core enums and error handling patterns.

Deliverables:
- `Include/CorrelationEngine.mqh` with Pearson correlation and strength classification.
- `Tests/test_correlation.mq5` script that prints pass/fail for known datasets.

## Milestone 2: Data Manager (Symbols + Timeframes + Caching)
Scope:
- Parse symbol/timeframe inputs.
- Fetch price data via MT5 APIs.
- Cache data by symbol/timeframe with invalidation rules.

Deliverables:
- `Include/DataManager.mqh` with parsing and data retrieval.
- Basic cache invalidation on new bar or time interval.

## Milestone 3: Matrix Build (Multi-Symbol/Timeframe)
Scope:
- Build correlation matrix across symbol lists for a selected timeframe.
- Optimize pair calculations and handle missing data.

Deliverables:
- `CCorrelationEngine::BuildMatrix` implemented with data validity checks.
- Symmetric matrix handling and EMPTY_VALUE on failures.

## Milestone 4: Display (Heatmap Rendering)
Scope:
- Render matrix as chart objects.
- Apply color mapping and labels.

Deliverables:
- `Include/MatrixDisplay.mqh` with draw/update/clear.
- Legend and headers.

## Milestone 5: Alerts + Divergence
Scope:
- Divergence detection and alert routing.
- Cooldown logic.

Deliverables:
- `Include/AlertManager.mqh` with push/email/sound hooks.
- Divergence check integration in main indicator.

## Milestone 6: Integration + Polishing
Scope:
- Wire everything into the main indicator lifecycle.
- Performance tuning and documentation updates.

Deliverables:
- `Indicators/MultiTimeframeCorrelation.mq5` fully wired.
- Performance optimizations and cleanup routines.

---

## Current Implementation Progress
- Milestone 1: Complete (code implemented; runtime validation pending MT5/MetaEditor on Windows).
- Milestone 2: Complete (code implemented; runtime validation pending MT5/MetaEditor on Windows).
- Milestone 3: Complete (code implemented; runtime validation pending MT5/MetaEditor on Windows).
- Milestone 4: Complete (code implemented; runtime validation pending MT5/MetaEditor on Windows).
- Milestone 5: Complete (code implemented; runtime validation pending MT5/MetaEditor on Windows).
- Milestone 6: Complete (code implemented; runtime validation pending MT5/MetaEditor on Windows).
- Milestone 7: Complete (multi-timeframe stacked panels + chart interactions implemented; runtime validation pending MT5/MetaEditor on Windows).
- Milestone 8: Complete (historical-vs-recent divergence windows + breakdown/recovery/threshold alerts implemented; runtime validation pending MT5/MetaEditor on Windows).
- Milestone 9: Complete (timestamped history tracking + stability metrics + historical CSV export implemented; runtime validation pending MT5/MetaEditor on Windows).
- Milestone 10: Complete (cell hover tooltips + color-blind palette + incremental pooled rendering implemented; runtime validation pending MT5/MetaEditor on Windows).
- Milestone 11: Complete (expanded correlation edge-case tests + DataManager parsing/cache-flow tests implemented; runtime validation pending MT5/MetaEditor on Windows).

---

## Doc Gaps (Partial / Not Implemented)

Not Implemented:
- None in current milestone plan (runtime validation still pending MT5/Windows).

---

## New Milestone Plan (Post-MVP)

## Milestone 7: Multi-Timeframe UI + Interactions
Scope:
- Render multiple timeframes in a stacked or grid layout.
- Add right-click refresh and basic UI actions.
- Improve labels for clarity when multiple timeframes are shown.

Deliverables:
- Updated `MatrixDisplay` to support multi-panel layout.
- Updated indicator to render all configured timeframes.
- `OnChartEvent` handlers for refresh and visibility toggles.

## Milestone 8: Advanced Alerts + Divergence Windows
Scope:
- Implement historical vs recent window divergence.
- Add breakdown/recovery/threshold alert logic.
- Ensure cooldown and per-pair tracking per timeframe.

Deliverables:
- Expanded divergence calculation using two windows.
- AlertManager integration for multiple alert types.
- Configurable thresholds per alert type.

## Milestone 9: Historical Tracking + Export
Scope:
- Track correlation history and stability metrics.
- Export history to CSV with timestamps and stats.

Deliverables:
- History storage for per-pair correlations.
- Standard deviation or stability metric calculation.
- `ExportCorrelations` enhancements for historical output.

## Milestone 10: UX + Performance Hardening
Scope:
- Tooltips on hover with precise correlation values.
- Color-blind accessibility palette option.
- Incremental updates and object pooling.

Deliverables:
- Tooltip display for matrix cells.
- Alternative palette config.
- Optimized rendering and update flow.

## Milestone 11: Testing Expansion
Scope:
- Broader unit tests for correlation edge cases.
- DataManager caching behavior tests (where feasible).

Deliverables:
- Additional test scripts with known datasets.
- Logging and assertions for cache refresh behavior.
