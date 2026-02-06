#property script_show_inputs

#include <CorrelationEngine.mqh>
#include <DataManager.mqh>
#include <Logger.mqh>

input string   InpSymbols = "EURUSD,GBPUSD,USDJPY,AUDUSD,USDCAD";
input string   InpTimeframes = "H1,H4,D1";
input int      InpLookbackBars = 100;
input string   InpOutputPrefix = "correlation_export";
input bool     InpExportHistorical = true;
input int      InpHistoryBars = 500;
input int      InpHistoryStep = 5;
input int      InpStabilityWindow = 20;
input ENUM_LOG_LEVEL InpLogLevel = LOG_ERROR;

/**
 * Computes average over an array window.
 * @param values Input values.
 * @param start Start index.
 * @param len Number of elements.
 * @return Mean value.
 */
double WindowMean(const double &values[], int start, int len)
{
    if(len <= 0)
        return EMPTY_VALUE;

    double sum = 0.0;
    for(int i = start; i < start + len; i++)
        sum += values[i];
    return sum / len;
}

/**
 * Computes standard deviation over an array window.
 * @param values Input values.
 * @param start Start index.
 * @param len Number of elements.
 * @return Std dev or EMPTY_VALUE.
 */
double WindowStdDev(const double &values[], int start, int len)
{
    if(len <= 1)
        return EMPTY_VALUE;

    double mean = WindowMean(values, start, len);
    double var = 0.0;
    for(int i = start; i < start + len; i++)
    {
        double d = values[i] - mean;
        var += d * d;
    }
    return MathSqrt(var / len);
}

/**
 * Exports correlation matrices to CSV files per timeframe.
 * @return 0 on success, non-zero on error.
 */
int OnStart()
{
    g_logger.SetLevel(InpLogLevel);

    CDataManager data;
    if(!data.Initialize(InpSymbols, InpTimeframes, 0))
    {
        g_logger.Error("ExportCorrelations: Failed to initialize data manager.");
        return 1;
    }

    CCorrelationEngine engine;
    if(!engine.Initialize(InpLookbackBars, 0.3))
    {
        g_logger.Error("ExportCorrelations: Failed to initialize correlation engine.");
        return 1;
    }

    string symbols[];
    ENUM_TIMEFRAMES timeframes[];
    data.GetSymbols(symbols);
    data.GetTimeframes(timeframes);

    if(ArraySize(symbols) <= 1 || ArraySize(timeframes) <= 0)
    {
        g_logger.Error("ExportCorrelations: Insufficient symbols or timeframes.");
        return 1;
    }

    int history_step = InpHistoryStep;
    if(history_step <= 0)
        history_step = 1;

    int stability_window = InpStabilityWindow;
    if(stability_window < 2)
        stability_window = 2;

    for(int t = 0; t < ArraySize(timeframes); t++)
    {
        ENUM_TIMEFRAMES tf = timeframes[t];
        string date = TimeToString(TimeCurrent(), TIME_DATE);
        string filename = StringFormat("%s_%s_%s.csv", InpOutputPrefix, EnumToString(tf), date);

        ResetLastError();
        int handle = FileOpen(filename, FILE_WRITE | FILE_CSV);
        if(handle == INVALID_HANDLE)
        {
            int err = GetLastError();
            g_logger.Error(StringFormat(
                "ExportCorrelations: FileOpen failed. file=%s, err=%d",
                filename, err));
            continue;
        }

        FileWrite(handle, "Timestamp", "Timeframe", "Symbol1", "Symbol2", "Correlation", "Strength");

        double matrix[][];
        if(!engine.BuildMatrix(matrix, symbols, tf, data))
        {
            FileClose(handle);
            continue;
        }

        int size = ArraySize(symbols);
        for(int i = 0; i < size; i++)
        {
            for(int j = i + 1; j < size; j++)
            {
                double corr = matrix[i][j];
                if(corr == EMPTY_VALUE)
                    continue;

                string strength;
                ENUM_CORRELATION_STRENGTH s = engine.GetCorrelationStrength(corr);
                switch(s)
                {
                    case CORR_STRONG_POSITIVE: strength = "STRONG_POSITIVE"; break;
                    case CORR_MODERATE_POSITIVE: strength = "MODERATE_POSITIVE"; break;
                    case CORR_WEAK: strength = "WEAK"; break;
                    case CORR_MODERATE_NEGATIVE: strength = "MODERATE_NEGATIVE"; break;
                    case CORR_STRONG_NEGATIVE: strength = "STRONG_NEGATIVE"; break;
                    default: strength = "UNKNOWN"; break;
                }

                FileWrite(handle,
                          TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES),
                          EnumToString(tf),
                          symbols[i],
                          symbols[j],
                          DoubleToString(corr, 4),
                          strength);
            }
        }

        FileClose(handle);
        g_logger.Debug("ExportCorrelations: Exported to: " + filename);

        if(!InpExportHistorical)
            continue;

        string hist_file = StringFormat("%s_history_%s_%s.csv", InpOutputPrefix, EnumToString(tf), date);
        ResetLastError();
        int hist = FileOpen(hist_file, FILE_WRITE | FILE_CSV);
        if(hist == INVALID_HANDLE)
        {
            int err = GetLastError();
            g_logger.Error(StringFormat(
                "ExportCorrelations: FileOpen failed for history file. file=%s, err=%d",
                hist_file, err));
            continue;
        }

        FileWrite(hist,
                  "Shift", "Timestamp", "Timeframe", "Symbol1", "Symbol2",
                  "Correlation", "RollingMean", "RollingStdDev", "Samples");

        int hist_bars = InpHistoryBars;
        if(hist_bars <= InpLookbackBars)
            hist_bars = InpLookbackBars + history_step;

        double all_prices[][];
        datetime all_times[][];
        bool ok[];
        int usable_bars[];

        int symbol_count = ArraySize(symbols);
        ArrayResize(all_prices, symbol_count);
        ArrayResize(all_times, symbol_count);
        ArrayResize(ok, symbol_count);
        ArrayResize(usable_bars, symbol_count);

        for(int i = 0; i < symbol_count; i++)
        {
            ArrayResize(all_prices[i], hist_bars);
            ArrayResize(all_times[i], hist_bars);
            ArraySetAsSeries(all_prices[i], true);
            ArraySetAsSeries(all_times[i], true);

            ResetLastError();
            int copied_price = CopyClose(symbols[i], tf, 0, hist_bars, all_prices[i]);
            int err_price = GetLastError();
            ResetLastError();
            int copied_time = CopyTime(symbols[i], tf, 0, hist_bars, all_times[i]);
            int err_time = GetLastError();

            int copied = MathMin(copied_price, copied_time);
            usable_bars[i] = copied;
            ok[i] = (copied >= InpLookbackBars);
            if(!ok[i])
            {
                g_logger.Error(StringFormat(
                    "ExportCorrelations: history data copy failed/insufficient. symbol=%s, timeframe=%s, requested=%d, copied_price=%d, err_price=%d, copied_time=%d, err_time=%d",
                    symbols[i], EnumToString(tf), hist_bars, copied_price, err_price, copied_time, err_time));
            }
        }

        for(int i = 0; i < symbol_count; i++)
        {
            if(!ok[i])
                continue;

            for(int j = i + 1; j < symbol_count; j++)
            {
                if(!ok[j])
                    continue;

                int pair_usable = MathMin(usable_bars[i], usable_bars[j]);
                if(pair_usable < InpLookbackBars)
                    continue;

                double pair_corrs[];
                int corr_count = 0;

                for(int shift = 0; shift + InpLookbackBars <= pair_usable; shift += history_step)
                {
                    double w1[];
                    double w2[];
                    ArrayResize(w1, InpLookbackBars);
                    ArrayResize(w2, InpLookbackBars);

                    for(int k = 0; k < InpLookbackBars; k++)
                    {
                        w1[k] = all_prices[i][shift + k];
                        w2[k] = all_prices[j][shift + k];
                    }

                    double corr = engine.CalculateCorrelation(w1, w2, InpLookbackBars);
                    if(corr == EMPTY_VALUE)
                        continue;

                    ArrayResize(pair_corrs, corr_count + 1);
                    pair_corrs[corr_count] = corr;
                    corr_count++;

                    int start = corr_count - stability_window;
                    if(start < 0)
                        start = 0;
                    int len = corr_count - start;

                    double mean = WindowMean(pair_corrs, start, len);
                    double stddev = WindowStdDev(pair_corrs, start, len);

                    string stddev_text = (stddev == EMPTY_VALUE) ? "" : DoubleToString(stddev, 6);

                    datetime ts = all_times[i][shift];
                    FileWrite(hist,
                              shift,
                              TimeToString(ts, TIME_DATE | TIME_MINUTES),
                              EnumToString(tf),
                              symbols[i],
                              symbols[j],
                              DoubleToString(corr, 6),
                              DoubleToString(mean, 6),
                              stddev_text,
                              len);
                }
            }
        }

        FileClose(hist);
        g_logger.Debug("ExportCorrelations: Exported history to: " + hist_file);
    }

    return 0;
}
