# 04 Structure Diagrams

## Repository Structure

```text
CorreletionMatrix/
├── Include/
│   ├── Constants.mqh
│   ├── Logger.mqh
│   ├── DataManager.mqh
│   ├── CorrelationEngine.mqh
│   ├── MatrixDisplay.mqh
│   └── AlertManager.mqh
├── Indicators/
│   └── MultiTimeframeCorrelation.mq5
├── Scripts/
│   ├── ExportCorrelations.mq5
│   └── CorrelationBacktest.mq5
├── Tests/
│   ├── test_correlation.mq5
│   ├── test_correlation_edge_cases.mq5
│   └── test_data_manager.mq5
├── Docs/
├── install.bat
└── uninstall.bat
```

## Include Dependency Graph

```mermaid
flowchart LR
    C[Constants.mqh]
    L[Logger.mqh]
    D[DataManager.mqh]
    E[CorrelationEngine.mqh]
    M[MatrixDisplay.mqh]
    A[AlertManager.mqh]
    I[MultiTimeframeCorrelation.mq5]
    S1[ExportCorrelations.mq5]
    S2[CorrelationBacktest.mq5]

    D --> C
    D --> L
    E --> D
    E --> C
    E --> L
    M --> C
    A --> C

    I --> C
    I --> L
    I --> D
    I --> E
    I --> M
    I --> A

    S1 --> E
    S1 --> D
    S1 --> L

    S2 --> E
    S2 --> L
```

## Runtime Data Flow

```mermaid
flowchart TD
    A[Inputs] --> B[DataManager]
    B --> C[Price cache and retrieval]
    C --> D[CorrelationEngine]
    D --> E[Matrix per timeframe]
    E --> F[MatrixDisplay panel i]
    E --> G[Alert checks]
    G --> H[AlertManager cooldown gate]
    H --> I[Terminal/Push/Email/Sound]
    E --> J[History state update]
    J --> K[Optional CSV exports]
    A --> T[Logger level]
    T --> U[Diagnostics output]
```

## Chart Object Naming Layout

Each panel has unique prefix, e.g. `CORR_0_`, `CORR_1_`, `CORR_2_`.

Objects generated per panel:

- `CORR_i_TITLE`
- `CORR_i_LEGEND`
- `CORR_i_HDR_R_<row>`
- `CORR_i_HDR_C_<col>`
- `CORR_i_CELL_<row>_<col>`
- `CORR_i_LABEL_<row>_<col>`

This avoids collisions across timeframe panels and allows bulk visibility operations per panel prefix.
