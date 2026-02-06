#property indicator_chart_window

#include <Constants.mqh>
#include <CorrelationEngine.mqh>
#include <DataManager.mqh>
#include <MatrixDisplay.mqh>
#include <AlertManager.mqh>
#include <Logger.mqh>

//==================== Data & Refresh ====================//
input string   InpSymbols = "EURUSD,GBPUSD,USDJPY,AUDUSD,USDCAD"; // Comma-separated symbols to include.
input string   InpTimeframes = "H1,H4,D1";                        // Comma-separated timeframes (e.g., M15,H1,D1).
input int      InpLookbackBars = DEFAULT_LOOKBACK;                // Bars used per correlation calculation window.
input int      InpUpdateInterval = 60;                            // Refresh interval in seconds.

//==================== Display & Layout ====================//
input int      InpXPosition = 20;                // Left offset in pixels for the first panel.
input int      InpYPosition = 50;                // Top offset in pixels for the first panel.
input int      InpCellSize = DEFAULT_CELL_SIZE;  // Matrix cell size in pixels.
input color    InpPositiveColor = clrGreen;      // Base color for positive correlation values.
input color    InpNegativeColor = clrRed;        // Base color for negative correlation values.
input color    InpNeutralColor = clrGray;        // Base color for weak/neutral correlation values.
input bool     InpUseColorBlindPalette = false;  // Use blue/orange/silver palette for accessibility.
input bool     InpEnableCellTooltips = true;     // Show symbol-pair + value tooltip on hover.

//==================== Alert Channels ====================//
input bool     InpEnablePush = true;                 // Send MT5 mobile push notifications.
input bool     InpEnableEmail = false;               // Send MT5 email notifications.
input bool     InpEnableSound = true;                // Play terminal sound when alerts fire.
input int      InpAlertCooldown = DEFAULT_COOLDOWN;  // Minimum seconds between same-key alerts.

//==================== Alert Logic ====================//
input double   InpDivergenceThreshold = 0.3; // Min abs difference between historical/recent averages.
input int      InpRecentWindow = 10;         // Recent window size (bars) for regime comparison.
input int      InpHistoricalWindow = 40;     // Historical baseline window size (bars).
input double   InpThresholdLevel = 0.8;      // Abs correlation crossing level for threshold alerts.
input double   InpStrongLevel = 0.7;         // Baseline strength needed before breakdown checks.
input double   InpBreakdownDrop = 0.3;       // Min drop from baseline to mark breakdown.
input double   InpRecoveryBand = 0.15;       // Distance-to-baseline to mark recovery.

//==================== History & Export ====================//
input int      InpStoredHistoryLimit = 300;         // Max stored samples per symbol-pair/timeframe key.
input int      InpStabilityWindow = 20;             // Rolling window for mean/stddev export metrics.
input bool     InpExportHistoryOnDeinit = false;    // Export history CSV automatically on indicator removal.
input string   InpHistoryExportPrefix = "correlation_history"; // Prefix for history export files.

//==================== Interaction & Telemetry ====================//
input bool           InpEnableRightClickRefresh = true; // Right-click edge triggers full refresh.
input ENUM_LOG_LEVEL InpLogLevel = LOG_ERROR;           // Runtime logs: LOG_OFF, LOG_ERROR, LOG_DEBUG.

CCorrelationEngine g_engine;
CDataManager g_data;
CMatrixDisplay g_displays[MAX_TIMEFRAMES];
CAlertManager g_alerts;

string g_symbols[];
ENUM_TIMEFRAMES g_timeframes[];
bool g_panels_visible = true;
bool g_right_mouse_down = false;

/**
 * Rolling history and alert state for a symbol pair.
 */
struct PairHistory
{
    string key;
    string symbol1;
    string symbol2;
    ENUM_TIMEFRAMES timeframe;
    double values[];
    datetime times[];
    int count;
    bool has_prev;
    double prev_corr;
    bool breakdown_active;
};

PairHistory g_history[];

/**
 * Finds history index for a key.
 * @param key History key.
 * @return Index or -1.
 */
int FindHistoryIndex(const string key)
{
    for(int i = 0; i < ArraySize(g_history); i++)
    {
        if(g_history[i].key == key)
            return i;
    }
    return -1;
}

/**
 * Returns the effective max history size.
 * @return Max history elements to retain.
 */
int GetHistoryLimit()
{
    int base = InpStoredHistoryLimit;
    if(base < 20)
        base = 20;

    int recent_window = (InpRecentWindow < 2) ? 2 : InpRecentWindow;
    int historical_window = (InpHistoricalWindow < 2) ? 2 : InpHistoricalWindow;
    int required = recent_window + historical_window;
    if(base < required)
        base = required;

    return base;
}

/**
 * Updates rolling history for a key.
 * @param key History key.
 * @param symbol1 First symbol.
 * @param symbol2 Second symbol.
 * @param tf Timeframe.
 * @param value New correlation value.
 * @param ts Timestamp.
 * @return none
 */
void UpdateHistory(const string key, const string symbol1, const string symbol2,
                   ENUM_TIMEFRAMES tf, double value, datetime ts)
{
    int idx = FindHistoryIndex(key);
    if(idx < 0)
    {
        int size = ArraySize(g_history);
        ArrayResize(g_history, size + 1);
        idx = size;
        g_history[idx].key = key;
        g_history[idx].symbol1 = symbol1;
        g_history[idx].symbol2 = symbol2;
        g_history[idx].timeframe = tf;
        g_history[idx].count = 0;
        ArrayResize(g_history[idx].values, 0);
        ArrayResize(g_history[idx].times, 0);
        g_history[idx].has_prev = false;
        g_history[idx].prev_corr = EMPTY_VALUE;
        g_history[idx].breakdown_active = false;
    }

    PairHistory &h = g_history[idx];
    int limit = GetHistoryLimit();

    if(h.count < limit)
    {
        ArrayResize(h.values, h.count + 1);
        ArrayResize(h.times, h.count + 1);
        h.values[h.count] = value;
        h.times[h.count] = ts;
        h.count++;
    }
    else
    {
        for(int i = 1; i < h.count; i++)
        {
            h.values[i - 1] = h.values[i];
            h.times[i - 1] = h.times[i];
        }
        h.values[h.count - 1] = value;
        h.times[h.count - 1] = ts;
    }
}

/**
 * Computes average over a history window.
 * @param key History key.
 * @param offset_from_end Offset from newest value.
 * @param window Window length.
 * @return Window average or EMPTY_VALUE.
 */
double GetHistoryWindowAverage(const string key, int offset_from_end, int window)
{
    int idx = FindHistoryIndex(key);
    if(idx < 0)
        return EMPTY_VALUE;

    PairHistory &h = g_history[idx];
    if(window <= 0 || h.count <= 0)
        return EMPTY_VALUE;
    if(offset_from_end < 0)
        return EMPTY_VALUE;

    int end = h.count - 1 - offset_from_end;
    int start = end - window + 1;
    if(start < 0 || end < 0 || start > end)
        return EMPTY_VALUE;

    double sum = 0.0;
    for(int i = start; i <= end; i++)
        sum += h.values[i];

    return sum / window;
}

/**
 * Computes a sample standard deviation on a window of values.
 * @param values Input values.
 * @param start Start index.
 * @param length Number of points.
 * @return Standard deviation or EMPTY_VALUE.
 */
double ComputeStdDevWindow(const double &values[], int start, int length)
{
    if(length <= 1)
        return EMPTY_VALUE;

    double sum = 0.0;
    for(int i = start; i < start + length; i++)
        sum += values[i];
    double mean = sum / length;

    double var = 0.0;
    for(int i = start; i < start + length; i++)
    {
        double d = values[i] - mean;
        var += d * d;
    }

    return MathSqrt(var / length);
}

/**
 * Exports per-pair history and stability stats to CSV.
 * @return true if file was created.
 */
bool ExportHistoryToCsv()
{
    string date = TimeToString(TimeCurrent(), TIME_DATE);
    string filename = StringFormat("%s_%s.csv", InpHistoryExportPrefix, date);
    ResetLastError();
    int handle = FileOpen(filename, FILE_WRITE | FILE_CSV);
    if(handle == INVALID_HANDLE)
    {
        int err = GetLastError();
        g_logger.Error(StringFormat(
            "Indicator: FileOpen failed for history export. file=%s, err=%d",
            filename, err));
        return false;
    }

    FileWrite(handle,
              "Key", "Timeframe", "Symbol1", "Symbol2",
              "Timestamp", "Correlation", "RollingMean", "RollingStdDev", "Samples");

    int stability = InpStabilityWindow;
    if(stability < 2)
        stability = 2;

    for(int hidx = 0; hidx < ArraySize(g_history); hidx++)
    {
        PairHistory &h = g_history[hidx];
        for(int i = 0; i < h.count; i++)
        {
            int start = i - stability + 1;
            if(start < 0)
                start = 0;
            int len = i - start + 1;

            double mean = 0.0;
            for(int j = start; j <= i; j++)
                mean += h.values[j];
            mean /= len;

            double stddev = ComputeStdDevWindow(h.values, start, len);
            string stddev_text = (stddev == EMPTY_VALUE) ? "" : DoubleToString(stddev, 6);

            FileWrite(handle,
                      h.key,
                      EnumToString(h.timeframe),
                      h.symbol1,
                      h.symbol2,
                      TimeToString(h.times[i], TIME_DATE | TIME_SECONDS),
                      DoubleToString(h.values[i], 6),
                      DoubleToString(mean, 6),
                      stddev_text,
                      len);
        }
    }

    FileClose(handle);
    g_logger.Debug("Indicator: History exported to: " + filename);
    return true;
}

/**
 * Returns true when right mouse button is currently pressed.
 * @param state Mouse state string from CHARTEVENT_MOUSE_MOVE.
 * @return true if right button bit is set.
 */
bool IsRightMousePressed(const string state)
{
    int mask = (int)StringToInteger(state);
    return ((mask & 2) != 0);
}

/**
 * Initializes engine, data manager, display, and alerts.
 * @return true on success.
 */
bool InitComponents()
{
    if(!g_data.Initialize(InpSymbols, InpTimeframes, InpUpdateInterval))
        return false;

    if(!g_engine.Initialize(InpLookbackBars, InpDivergenceThreshold))
        return false;

    if(!g_alerts.Initialize(InpEnablePush, InpEnableEmail, InpEnableSound, InpAlertCooldown))
        return false;

    g_data.GetSymbols(g_symbols);
    g_data.GetTimeframes(g_timeframes);

    int symbols_count = ArraySize(g_symbols);
    int tf_count = ArraySize(g_timeframes);
    if(symbols_count <= 1 || tf_count <= 0)
        return false;

    int panel_height = (InpCellSize * (symbols_count + 2)) + 30;
    color pos_color = InpPositiveColor;
    color neg_color = InpNegativeColor;
    color neutral_color = InpNeutralColor;
    if(InpUseColorBlindPalette)
    {
        // Blue/orange/gray palette improves distinction for common red-green deficiencies.
        pos_color = clrDodgerBlue;
        neg_color = clrOrange;
        neutral_color = clrSilver;
    }

    for(int i = 0; i < tf_count; i++)
    {
        int panel_y = InpYPosition + (i * panel_height);
        string prefix = CORRELATION_PREFIX + IntegerToString(i) + "_";
        if(!g_displays[i].Initialize(InpXPosition, panel_y, InpCellSize,
                                     pos_color, neg_color, neutral_color, prefix))
            return false;
        g_displays[i].SetTooltipsEnabled(InpEnableCellTooltips);
        g_displays[i].SetTitle("Correlation Matrix (" + EnumToString(g_timeframes[i]) + ")");
    }

    return true;
}

/**
 * Evaluates alert types for a timeframe.
 * @param matrix Correlation matrix.
 * @param symbols Symbol list.
 * @param tf Timeframe.
 * @return none
 */
void CheckAlerts(const double &matrix[][], const string &symbols[], ENUM_TIMEFRAMES tf)
{
    int recent_window = (InpRecentWindow < 2) ? 2 : InpRecentWindow;
    int historical_window = (InpHistoricalWindow < 2) ? 2 : InpHistoricalWindow;

    int count = ArraySize(symbols);
    for(int i = 0; i < count; i++)
    {
        for(int j = i + 1; j < count; j++)
        {
            double corr = matrix[i][j];
            if(corr == EMPTY_VALUE)
                continue;

            string key = symbols[i] + "_" + symbols[j] + "_" + EnumToString(tf);
            UpdateHistory(key, symbols[i], symbols[j], tf, corr, TimeCurrent());

            int idx = FindHistoryIndex(key);
            if(idx < 0)
                continue;
            PairHistory &h = g_history[idx];

            double recent_avg = GetHistoryWindowAverage(key, 0, recent_window);
            double historical_avg = GetHistoryWindowAverage(key, recent_window, historical_window);

            if(recent_avg != EMPTY_VALUE && historical_avg != EMPTY_VALUE &&
               g_engine.DetectDivergence(historical_avg, recent_avg))
            {
                string msg = StringFormat("%s/%s %s recent %.2f vs historical %.2f",
                                          symbols[i], symbols[j],
                                          EnumToString(tf), recent_avg, historical_avg);
                g_alerts.SendAlert(msg, ALERT_DIVERGENCE, key + "_DIV");
            }

            if(h.has_prev &&
               MathAbs(h.prev_corr) < InpThresholdLevel &&
               MathAbs(corr) >= InpThresholdLevel)
            {
                string msg = StringFormat("%s/%s %s threshold crossed: %.2f",
                                          symbols[i], symbols[j],
                                          EnumToString(tf), corr);
                g_alerts.SendAlert(msg, ALERT_THRESHOLD, key + "_THR");
            }

            if(recent_avg != EMPTY_VALUE && historical_avg != EMPTY_VALUE)
            {
                bool historically_strong = MathAbs(historical_avg) >= InpStrongLevel;
                bool dropped = MathAbs(historical_avg - corr) >= InpBreakdownDrop;

                if(historically_strong && dropped && !h.breakdown_active)
                {
                    string msg = StringFormat("%s/%s %s breakdown: current %.2f from baseline %.2f",
                                              symbols[i], symbols[j],
                                              EnumToString(tf), corr, historical_avg);
                    g_alerts.SendAlert(msg, ALERT_BREAKDOWN, key + "_BRK");
                    h.breakdown_active = true;
                }
            }

            if(h.breakdown_active && recent_avg != EMPTY_VALUE && historical_avg != EMPTY_VALUE)
            {
                if(MathAbs(corr - historical_avg) <= InpRecoveryBand)
                {
                    string msg = StringFormat("%s/%s %s recovery: current %.2f near baseline %.2f",
                                              symbols[i], symbols[j],
                                              EnumToString(tf), corr, historical_avg);
                    g_alerts.SendAlert(msg, ALERT_RECOVERY, key + "_RCV");
                    h.breakdown_active = false;
                }
            }

            h.prev_corr = corr;
            h.has_prev = true;
        }
    }
}

/**
 * Builds and renders the matrix for a timeframe.
 * @param tf Timeframe.
 * @return none
 */
void RefreshForTimeframe(const int index, ENUM_TIMEFRAMES tf)
{
    if(index < 0 || index >= ArraySize(g_timeframes))
        return;

    double matrix[][];
    if(g_engine.BuildMatrix(matrix, g_symbols, tf, g_data))
    {
        g_displays[index].DrawHeatmap(matrix, g_symbols);
        CheckAlerts(matrix, g_symbols, tf);
    }
}

/**
 * Refreshes all configured timeframe panels.
 * @param forceDataRefresh true to force cache invalidation before render.
 * @return none
 */
void RefreshAllTimeframes(bool forceDataRefresh = false)
{
    if(forceDataRefresh)
        g_data.RefreshCache();

    int tf_count = ArraySize(g_timeframes);
    for(int i = 0; i < tf_count; i++)
        RefreshForTimeframe(i, g_timeframes[i]);
}

/**
 * Indicator initialization.
 * @return INIT_SUCCEEDED or INIT_FAILED.
 */
int OnInit()
{
    g_logger.SetLevel(InpLogLevel);

    if(!InitComponents())
        return INIT_FAILED;

    if(InpEnableRightClickRefresh)
        ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, true);

    EventSetTimer(InpUpdateInterval);
    RefreshAllTimeframes(true);
    return INIT_SUCCEEDED;
}

/**
 * Indicator cleanup.
 * @param reason Deinit reason.
 * @return none
 */
void OnDeinit(const int reason)
{
    EventKillTimer();
    if(InpEnableRightClickRefresh)
        ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, false);
    int tf_count = ArraySize(g_timeframes);
    for(int i = 0; i < tf_count; i++)
        g_displays[i].Clear();
    g_data.Cleanup();
    g_alerts.Cleanup();
    if(InpExportHistoryOnDeinit)
        ExportHistoryToCsv();
    ArrayResize(g_history, 0);
}

/**
 * Timer callback for periodic refresh.
 * @return none
 */
void OnTimer()
{
    if(ArraySize(g_timeframes) <= 0)
        return;
    RefreshAllTimeframes(false);
}

/**
 * Chart event handler for UI interactions.
 * @param id Event id.
 * @param lparam Event long parameter.
 * @param dparam Event double parameter.
 * @param sparam Event string parameter.
 * @return none
 */
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
    if(id == CHARTEVENT_MOUSE_MOVE && InpEnableRightClickRefresh)
    {
        bool right_now = IsRightMousePressed(sparam);
        if(right_now && !g_right_mouse_down)
            RefreshAllTimeframes(true);
        g_right_mouse_down = right_now;
    }

    if(id == CHARTEVENT_KEYDOWN)
    {
        // 'R' forces a full data refresh.
        if(lparam == 82 || lparam == 114)
            RefreshAllTimeframes(true);

        // 'V' toggles panel visibility.
        if(lparam == 86 || lparam == 118)
        {
            g_panels_visible = !g_panels_visible;
            int tf_count = ArraySize(g_timeframes);
            for(int i = 0; i < tf_count; i++)
                g_displays[i].SetVisibility(g_panels_visible);
        }

        // 'E' exports in-memory history and stability metrics.
        if(lparam == 69 || lparam == 101)
            ExportHistoryToCsv();
    }

    // Chart refresh events (including user chart refresh actions) trigger redraw.
    if(id == CHARTEVENT_CHART_CHANGE)
        RefreshAllTimeframes(true);

    // Detect double-click on any panel title label.
    if(id == CHARTEVENT_OBJECT_CLICK)
    {
        int tf_count = ArraySize(g_timeframes);
        bool clicked_title = false;
        for(int i = 0; i < tf_count; i++)
        {
            if(sparam == g_displays[i].GetTitleObjectName())
            {
                clicked_title = true;
                break;
            }
        }

        if(clicked_title)
        {
            static uint last_click = 0;
            uint now = GetTickCount();
            if(now - last_click <= 400)
            {
                g_panels_visible = !g_panels_visible;
                for(int i = 0; i < tf_count; i++)
                    g_displays[i].SetVisibility(g_panels_visible);
                last_click = 0;
            }
            else
            {
                last_click = now;
            }
        }
    }
}

/**
 * Main calculation callback (unused for now).
 * @param rates_total Total bars.
 * @param prev_calculated Previously calculated bars.
 * @param begin Begin index.
 * @param price Price array.
 * @return rates_total
 */
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,
                const double &price[])
{
    // Optional: trigger refresh on new bar close if timer disabled.
    return rates_total;
}
