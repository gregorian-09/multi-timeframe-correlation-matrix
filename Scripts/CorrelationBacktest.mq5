#property script_show_inputs

#include <CorrelationEngine.mqh>
#include <Logger.mqh>

input string   InpSymbols = "EURUSD,GBPUSD,USDJPY,AUDUSD,USDCAD";
input ENUM_TIMEFRAMES InpTimeframe = PERIOD_H1;
input int      InpLookbackBars = 100;
input int      InpHistoryBars = 500;
input int      InpStep = 10;
input string   InpOutputPrefix = "correlation_backtest";
input ENUM_LOG_LEVEL InpLogLevel = LOG_ERROR;

/**
 * Runs a historical correlation backtest and exports to CSV.
 * @return 0 on success, non-zero on error.
 */
int OnStart()
{
    g_logger.SetLevel(InpLogLevel);

    string symbols[];
    int count = StringSplit(InpSymbols, ',', symbols);
    if(count <= 1)
    {
        g_logger.Error("CorrelationBacktest: Need at least two symbols.");
        return 1;
    }

    for(int i = 0; i < count; i++)
    {
        StringTrimLeft(symbols[i]);
        StringTrimRight(symbols[i]);
        if(SymbolInfoInteger(symbols[i], SYMBOL_EXIST) == 0)
        {
            g_logger.Error("CorrelationBacktest: Invalid symbol: " + symbols[i]);
            return 1;
        }
    }

    if(InpLookbackBars <= 1 || InpHistoryBars <= InpLookbackBars)
    {
        g_logger.Error("CorrelationBacktest: Invalid history or lookback settings.");
        return 1;
    }

    if(InpStep <= 0)
        InpStep = 1;

    CCorrelationEngine engine;
    if(!engine.Initialize(InpLookbackBars, 0.3))
        return 1;

    double prices[][];
    ArrayResize(prices, count);

    for(int i = 0; i < count; i++)
    {
        ArrayResize(prices[i], InpHistoryBars);
        ArraySetAsSeries(prices[i], true);
        ResetLastError();
        int copied = CopyClose(symbols[i], InpTimeframe, 0, InpHistoryBars, prices[i]);
        if(copied <= InpLookbackBars)
        {
            int err = GetLastError();
            g_logger.Error(StringFormat(
                "CorrelationBacktest: CopyClose failed/insufficient. symbol=%s, timeframe=%s, requested=%d, copied=%d, err=%d",
                symbols[i], EnumToString(InpTimeframe), InpHistoryBars, copied, err));
            return 1;
        }
    }

    string date = TimeToString(TimeCurrent(), TIME_DATE);
    string filename = StringFormat("%s_%s_%s.csv", InpOutputPrefix, EnumToString(InpTimeframe), date);
    ResetLastError();
    int handle = FileOpen(filename, FILE_WRITE | FILE_CSV);
    if(handle == INVALID_HANDLE)
    {
        int err = GetLastError();
        g_logger.Error(StringFormat(
            "CorrelationBacktest: FileOpen failed. file=%s, err=%d",
            filename, err));
        return 1;
    }

    FileWrite(handle, "Shift", "Timeframe", "Symbol1", "Symbol2", "Correlation");

    for(int shift = 0; shift + InpLookbackBars <= InpHistoryBars; shift += InpStep)
    {
        for(int i = 0; i < count; i++)
        {
            for(int j = i + 1; j < count; j++)
            {
                double w1[];
                double w2[];
                ArrayResize(w1, InpLookbackBars);
                ArrayResize(w2, InpLookbackBars);

                for(int k = 0; k < InpLookbackBars; k++)
                {
                    w1[k] = prices[i][shift + k];
                    w2[k] = prices[j][shift + k];
                }

                double corr = engine.CalculateCorrelation(w1, w2, InpLookbackBars);
                if(corr == EMPTY_VALUE)
                    continue;

                FileWrite(handle,
                          shift,
                          EnumToString(InpTimeframe),
                          symbols[i],
                          symbols[j],
                          DoubleToString(corr, 4));
            }
        }
    }

    FileClose(handle);
    g_logger.Debug("CorrelationBacktest: Backtest exported to: " + filename);
    return 0;
}
