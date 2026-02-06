#pragma once

// Data manager for symbol/timeframe parsing and cached price retrieval.

#include <Constants.mqh>
#include <Logger.mqh>

/**
 * Cached price data for a symbol/timeframe.
 */
struct CachedData
{
    string symbol;
    ENUM_TIMEFRAMES timeframe;
    double prices[];
    datetime last_update;
    datetime last_bar_time;
    int bar_count;
};

/**
 * Parses inputs, fetches price data, and manages cache.
 */
class CDataManager
{
private:
    string m_symbols[];
    ENUM_TIMEFRAMES m_timeframes[];
    int m_cache_seconds;
    CachedData m_cache[];

    /**
     * Trims whitespace from both ends of a string.
     * @param value Input string.
     * @return Trimmed string.
     */
    string Trim(const string value)
    {
        string out = value;
        StringTrimLeft(out);
        StringTrimRight(out);
        return out;
    }

    /**
     * Parses a timeframe token (e.g., H1) into ENUM_TIMEFRAMES.
     * @param token Timeframe token.
     * @param outTf Output timeframe enum.
     * @return true on success.
     */
    bool ParseTimeframeToken(const string token, ENUM_TIMEFRAMES &outTf)
    {
        string t = StringUpper(Trim(token));

        if(t == "M1")  { outTf = PERIOD_M1; return true; }
        if(t == "M5")  { outTf = PERIOD_M5; return true; }
        if(t == "M15") { outTf = PERIOD_M15; return true; }
        if(t == "M30") { outTf = PERIOD_M30; return true; }
        if(t == "H1")  { outTf = PERIOD_H1; return true; }
        if(t == "H4")  { outTf = PERIOD_H4; return true; }
        if(t == "D1")  { outTf = PERIOD_D1; return true; }
        if(t == "W1")  { outTf = PERIOD_W1; return true; }
        if(t == "MN1") { outTf = PERIOD_MN1; return true; }

        return false;
    }

    /**
     * Finds cache entry index for symbol/timeframe, or -1 if missing.
     * @param symbol Symbol name.
     * @param tf Timeframe.
     * @return Cache index or -1.
     */
    int FindCacheIndex(const string symbol, ENUM_TIMEFRAMES tf) const
    {
        for(int i = 0; i < ArraySize(m_cache); i++)
        {
            if(m_cache[i].symbol == symbol && m_cache[i].timeframe == tf)
                return i;
        }
        return -1;
    }

    /**
     * Determines if a cache entry should be refreshed.
     * @param entry Cache entry.
     * @return true if refresh is required.
     */
    bool ShouldRefreshCache(const CachedData &entry) const
    {
        if(entry.bar_count <= 0)
            return true;

        if(m_cache_seconds > 0)
        {
            if((TimeCurrent() - entry.last_update) >= m_cache_seconds)
                return true;
        }

        datetime times[];
        ResetLastError();
        int copied = CopyTime(entry.symbol, entry.timeframe, 0, 1, times);
        if(copied == 1)
        {
            if(times[0] != entry.last_bar_time)
                return true;
        }
        else
        {
            int err = GetLastError();
            g_logger.Error(StringFormat(
                "DataManager: CopyTime failed in ShouldRefreshCache. symbol=%s, timeframe=%s, requested=1, copied=%d, err=%d",
                entry.symbol, EnumToString(entry.timeframe), copied, err));
            // Fallback to refresh path when bar-time check is unavailable.
            return true;
        }

        return false;
    }

    /**
     * Loads price data into cache for the requested bars.
     * @param entry Cache entry.
     * @param bars Number of bars to load.
     * @return true on success.
     */
    bool LoadCache(CachedData &entry, int bars)
    {
        if(bars <= 0)
            return false;

        ArrayResize(entry.prices, bars);
        ArraySetAsSeries(entry.prices, true);

        ResetLastError();
        int copied = CopyClose(entry.symbol, entry.timeframe, 0, bars, entry.prices);
        if(copied <= 0)
        {
            int err = GetLastError();
            g_logger.Error(StringFormat(
                "DataManager: CopyClose failed in LoadCache. symbol=%s, timeframe=%s, requested=%d, copied=%d, err=%d",
                entry.symbol, EnumToString(entry.timeframe), bars, copied, err));
            return false;
        }

        entry.bar_count = copied;
        entry.last_update = TimeCurrent();

        datetime times[];
        ResetLastError();
        int copied_time = CopyTime(entry.symbol, entry.timeframe, 0, 1, times);
        if(copied_time == 1)
            entry.last_bar_time = times[0];
        else
        {
            int err = GetLastError();
            g_logger.Error(StringFormat(
                "DataManager: CopyTime failed after LoadCache. symbol=%s, timeframe=%s, requested=1, copied=%d, err=%d",
                entry.symbol, EnumToString(entry.timeframe), copied_time, err));
            entry.last_bar_time = 0;
        }

        return true;
    }

public:
    /**
     * Constructs the data manager with default cache settings.
     * @return none
     */
    CDataManager() : m_cache_seconds(DEFAULT_CACHE_SECONDS) {}

    /**
     * Initializes symbols, timeframes, and cache interval.
     * @param symbolsCsv Comma-separated symbols.
     * @param timeframesCsv Comma-separated timeframes.
     * @param cacheSeconds Cache interval in seconds.
     * @return true on success.
     */
    bool Initialize(const string symbolsCsv, const string timeframesCsv, int cacheSeconds = 60)
    {
        m_cache_seconds = cacheSeconds;

        if(!ParseSymbols(symbolsCsv))
            return false;
        if(!ParseTimeframes(timeframesCsv))
            return false;

        return true;
    }

    /**
     * Parses and validates symbol list.
     * @param symbolsCsv Comma-separated symbols.
     * @return true if at least one symbol is valid.
     */
    bool ParseSymbols(const string symbolsCsv)
    {
        string parts[];
        int count = StringSplit(symbolsCsv, ',', parts);
        if(count <= 0)
            return false;

        ArrayResize(m_symbols, 0);
        for(int i = 0; i < count; i++)
        {
            string sym = Trim(parts[i]);
            if(sym == "")
                continue;

            if(SymbolInfoInteger(sym, SYMBOL_EXIST) == 0)
                return false;

            int size = ArraySize(m_symbols);
            ArrayResize(m_symbols, size + 1);
            m_symbols[size] = sym;
        }

        return (ArraySize(m_symbols) > 0);
    }

    /**
     * Parses comma-separated symbols into an output array.
     * @param input Input string.
     * @param result Output symbol array.
     * @return Number of symbols parsed.
     */
    int ParseSymbols(const string input, string &result[])
    {
        if(!ParseSymbols(input))
        {
            ArrayResize(result, 0);
            return 0;
        }

        GetSymbols(result);
        return ArraySize(result);
    }

    /**
     * Parses timeframe list.
     * @param timeframesCsv Comma-separated timeframes.
     * @return true if at least one timeframe is valid.
     */
    bool ParseTimeframes(const string timeframesCsv)
    {
        string parts[];
        int count = StringSplit(timeframesCsv, ',', parts);
        if(count <= 0)
            return false;

        ArrayResize(m_timeframes, 0);
        for(int i = 0; i < count; i++)
        {
            ENUM_TIMEFRAMES tf;
            if(!ParseTimeframeToken(parts[i], tf))
                return false;

            int size = ArraySize(m_timeframes);
            ArrayResize(m_timeframes, size + 1);
            m_timeframes[size] = tf;
        }

        return (ArraySize(m_timeframes) > 0);
    }

    /**
     * Parses comma-separated timeframes into an output array.
     * @param input Input string.
     * @param result Output timeframe array.
     * @return Number of timeframes parsed.
     */
    int ParseTimeframes(const string input, ENUM_TIMEFRAMES &result[])
    {
        if(!ParseTimeframes(input))
        {
            ArrayResize(result, 0);
            return 0;
        }

        GetTimeframes(result);
        return ArraySize(result);
    }

    /**
     * Returns parsed symbol list.
     * @param outSymbols Output symbol array.
     * @return none
     */
    void GetSymbols(string &outSymbols[]) const
    {
        int size = ArraySize(m_symbols);
        ArrayResize(outSymbols, size);
        for(int i = 0; i < size; i++)
            outSymbols[i] = m_symbols[i];
    }

    /**
     * Returns parsed timeframe list.
     * @param outTimeframes Output timeframe array.
     * @return none
     */
    void GetTimeframes(ENUM_TIMEFRAMES &outTimeframes[]) const
    {
        int size = ArraySize(m_timeframes);
        ArrayResize(outTimeframes, size);
        for(int i = 0; i < size; i++)
            outTimeframes[i] = m_timeframes[i];
    }

    /**
     * Retrieves price data using cache where possible.
     * @param symbol Symbol name.
     * @param tf Timeframe.
     * @param bars Number of bars requested.
     * @param outPrices Output price array.
     * @return Number of prices copied, or -1 on error.
     */
    int GetPriceData(const string symbol, ENUM_TIMEFRAMES tf, int bars, double &outPrices[])
    {
        int idx = FindCacheIndex(symbol, tf);
        if(idx < 0)
        {
            int size = ArraySize(m_cache);
            ArrayResize(m_cache, size + 1);
            idx = size;
            m_cache[idx].symbol = symbol;
            m_cache[idx].timeframe = tf;
            m_cache[idx].bar_count = 0;
            m_cache[idx].last_update = 0;
            m_cache[idx].last_bar_time = 0;
        }

        CachedData &entry = m_cache[idx];
        if(ShouldRefreshCache(entry) || entry.bar_count < bars)
        {
            if(!LoadCache(entry, bars))
                return -1;
        }

        ArrayResize(outPrices, entry.bar_count);
        ArrayCopy(outPrices, entry.prices, 0, 0, entry.bar_count);
        ArraySetAsSeries(outPrices, true);
        return entry.bar_count;
    }

    /**
     * Returns the configured symbol count.
     * @return Symbol count.
     */
    int GetSymbolCount() const
    {
        return ArraySize(m_symbols);
    }

    /**
     * Returns the configured timeframe count.
     * @return Timeframe count.
     */
    int GetTimeframeCount() const
    {
        return ArraySize(m_timeframes);
    }

    /**
     * Forces refresh of all cached data.
     * @return none
     */
    void RefreshCache()
    {
        for(int i = 0; i < ArraySize(m_cache); i++)
        {
            m_cache[i].bar_count = 0;
            m_cache[i].last_update = 0;
            m_cache[i].last_bar_time = 0;
            ArrayResize(m_cache[i].prices, 0);
        }
    }

    /**
     * Releases cached data.
     * @return none
     */
    void Cleanup()
    {
        ArrayResize(m_cache, 0);
    }
};
