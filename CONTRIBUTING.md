# Contributing

Thanks for contributing.

## Development Rules

- Keep module boundaries clear:
- math in `CorrelationEngine`
- retrieval/caching in `DataManager`
- rendering in `MatrixDisplay`
- notifications/cooldown in `AlertManager`
- telemetry gating in `Logger`
- Follow existing MQL5 style and return conventions (`false`, `-1`, `EMPTY_VALUE`).
- Add/adjust docs when behavior or inputs change.

## Workflow

1. Create a focused branch.
2. Implement the smallest coherent change.
3. Update docs in `Docs/` and `FinalDocs/` if needed.
4. Add/update tests in `Tests/` where applicable.
5. Open a PR with scope, risk, and test evidence.

## Test Checklist (MT5)

- Compile `Indicators/MultiTimeframeCorrelation.mq5`.
- Run scripts:
- `Tests/test_correlation.mq5`
- `Tests/test_correlation_edge_cases.mq5`
- `Tests/test_data_manager.mq5`
- Validate hotkeys (`R`, `V`, `E`) and right-click refresh.
- Validate exports from `Scripts/ExportCorrelations.mq5`.

## PR Expectations

- Clear problem statement and solution summary.
- No unrelated file churn.
- Backward compatibility of existing inputs unless explicitly breaking.
- Logging remains level-gated (`InpLogLevel`).

## Reporting Issues

Include:

- MT5 build/version
- OS version
- broker/symbol examples
- exact errors from Experts/Journal logs
- reproduction steps
