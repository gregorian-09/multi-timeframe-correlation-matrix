# Architecture

## Overview

The system is modular and event-driven around the MT5 indicator lifecycle.

Primary modules:

- `MultiTimeframeCorrelation.mq5` (orchestrator)
- `CorrelationEngine` (math + matrix construction)
- `DataManager` (parsing + cache + market data access)
- `MatrixDisplay` (chart object rendering)
- `AlertManager` (notification + cooldown)
- `Logger` (runtime telemetry gating)

## Runtime Lifecycle

### OnInit

- Set log level
- Initialize data/engine/display/alerts
- Create one display panel per configured timeframe
- Enable timer and optional mouse tracking
- Perform initial full refresh

### OnTimer

- Call `RefreshAllTimeframes(false)`
- For each timeframe:
  - build matrix
  - draw panel (incremental repaint)
  - evaluate alerts using rolling windows/history

### OnChartEvent

- `R` -> forced refresh
- `V` -> visibility toggle
- `E` -> history export
- right-click edge -> forced refresh (if enabled)
- title double-click -> visibility toggle

### OnDeinit

- disable timer / mouse tracking
- clear panel objects
- cleanup caches/history/alert state
- optional export on deinit

## Data Flow

1. Inputs -> parsed symbol/timeframe arrays
2. DataManager supplies close data using cache policy
3. CorrelationEngine builds symmetric matrix
4. MatrixDisplay updates changed cells only
5. Alert logic consumes matrix + rolling history
6. AlertManager sends notifications with cooldown gating

## Cache and Refresh Policy

`DataManager` cache invalidates on:

- empty cache entry
- cache timeout (`cacheSeconds`)
- bar-time change detection (`CopyTime`)
- explicit `RefreshCache()`

If bar-time check fails, it falls back to refresh path and logs an error.

## Rendering Strategy

- Prefix-isolated object namespaces per timeframe panel
- Object pooling for cells/labels
- last-value cache to skip unchanged repaints
- optional per-cell hover tooltip

## Alert Decision Model

Per pair/timeframe:

- Compute recent and historical averages from rolling history
- Trigger divergence, threshold, breakdown, recovery conditions
- Use keyed cooldown entries to prevent alert spam

## See Also

- `SYSTEM_ARCHITECTURE.md`
- `UML_DIAGRAMS.md`
- `STRUCTURE_DIAGRAMS.md`
