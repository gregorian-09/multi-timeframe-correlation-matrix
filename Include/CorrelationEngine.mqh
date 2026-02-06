#pragma once

// Core correlation engine for Pearson calculations.

#include <DataManager.mqh>
#include <Constants.mqh>
#include <Logger.mqh>

/**
 * Correlation strength classification bands.
 * @enum ENUM_CORRELATION_STRENGTH
 */
enum ENUM_CORRELATION_STRENGTH
{
    CORR_STRONG_POSITIVE,   // value >= 0.7
    CORR_MODERATE_POSITIVE, // 0.3 <= value < 0.7
    CORR_WEAK,              // -0.3 < value < 0.3
    CORR_MODERATE_NEGATIVE, // -0.7 < value <= -0.3
    CORR_STRONG_NEGATIVE    // value <= -0.7
};

/**
 * Provides correlation calculations and matrix building helpers.
 */
class CCorrelationEngine
{
private:
    int m_lookback_bars;
    double m_divergence_threshold;

public:
    /**
     * Constructs the engine with default settings.
     * @return none
     */
    CCorrelationEngine() : m_lookback_bars(DEFAULT_LOOKBACK), m_divergence_threshold(0.3) {}

    /**
     * Initializes engine settings.
     * @param lookbackBars Number of bars used for correlation.
     * @param divergenceThreshold Threshold for divergence detection.
     * @return true on success.
     */
    bool Initialize(int lookbackBars, double divergenceThreshold)
    {
        if(lookbackBars <= 1)
            return false;
        if(divergenceThreshold < 0.0)
            return false;

        m_lookback_bars = lookbackBars;
        m_divergence_threshold = divergenceThreshold;
        return true;
    }

    /**
     * Returns the configured lookback bars.
     * @return Lookback bars.
     */
    int GetLookbackBars() const { return m_lookback_bars; }
    /**
     * Returns the configured divergence threshold.
     * @return Divergence threshold.
     */
    double GetDivergenceThreshold() const { return m_divergence_threshold; }

    /**
     * Calculates Pearson correlation for two price arrays.
     * @param prices1 First price array.
     * @param prices2 Second price array.
     * @param count Number of elements to use.
     * @return Correlation coefficient or EMPTY_VALUE.
     */
    double CalculateCorrelation(const double &prices1[], const double &prices2[], int count)
    {
        if(count <= 1)
            return EMPTY_VALUE;
        if(ArraySize(prices1) < count || ArraySize(prices2) < count)
            return EMPTY_VALUE;

        double mean1 = 0.0;
        double mean2 = 0.0;

        for(int i = 0; i < count; i++)
        {
            mean1 += prices1[i];
            mean2 += prices2[i];
        }

        mean1 /= count;
        mean2 /= count;

        double num = 0.0;
        double den1 = 0.0;
        double den2 = 0.0;

        for(int i = 0; i < count; i++)
        {
            double d1 = prices1[i] - mean1;
            double d2 = prices2[i] - mean2;
            num += d1 * d2;
            den1 += d1 * d1;
            den2 += d2 * d2;
        }

        if(den1 <= 0.0 || den2 <= 0.0)
            return EMPTY_VALUE;

        double corr = num / MathSqrt(den1 * den2);

        if(corr > 1.0)
            corr = 1.0;
        if(corr < -1.0)
            corr = -1.0;

        return corr;
    }

    /**
     * Maps a correlation value to a strength bucket.
     * @param value Correlation coefficient.
     * @return Strength classification.
     */
    ENUM_CORRELATION_STRENGTH GetCorrelationStrength(double value)
    {
        if(value >= 0.7)
            return CORR_STRONG_POSITIVE;
        if(value >= 0.3)
            return CORR_MODERATE_POSITIVE;
        if(value > -0.3)
            return CORR_WEAK;
        if(value > -0.7)
            return CORR_MODERATE_NEGATIVE;
        return CORR_STRONG_NEGATIVE;
    }

    /**
     * Detects divergence using the configured threshold.
     * @param historicalCorr Historical baseline correlation.
     * @param currentCorr Current correlation.
     * @return true if divergence exceeds threshold.
     */
    bool DetectDivergence(double historicalCorr, double currentCorr) const
    {
        if(historicalCorr == EMPTY_VALUE || currentCorr == EMPTY_VALUE)
            return false;
        return MathAbs(historicalCorr - currentCorr) >= m_divergence_threshold;
    }

    /**
     * Detects divergence using symbol identifiers for context.
     * @param symbol1 First symbol.
     * @param symbol2 Second symbol.
     * @param historicalCorr Historical baseline correlation.
     * @param currentCorr Current correlation.
     * @return true if divergence exceeds threshold.
     */
    bool DetectDivergence(const string symbol1, const string symbol2,
                          double historicalCorr, double currentCorr) const
    {
        // Symbols currently unused; kept for API compatibility and future logging.
        return DetectDivergence(historicalCorr, currentCorr);
    }

    /**
     * Builds a correlation matrix for the given symbols and timeframe.
     * @param matrix Output matrix.
     * @param symbols Symbol list.
     * @param timeframe Timeframe for calculation.
     * @param data Data manager for price retrieval.
     * @param bars Lookback bars.
     * @return true on success.
     */
    bool BuildMatrix(double &matrix[][],
                     const string &symbols[],
                     ENUM_TIMEFRAMES timeframe,
                     CDataManager &data,
                     int bars)
    {
        int count = ArraySize(symbols);
        if(count <= 0 || bars <= 1)
            return false;

        ArrayResize(matrix, count);
        for(int i = 0; i < count; i++)
            ArrayResize(matrix[i], count);

        for(int i = 0; i < count; i++)
        {
            double prices_i[];
            if(data.GetPriceData(symbols[i], timeframe, bars, prices_i) <= 0)
            {
                for(int j = 0; j < count; j++)
                    matrix[i][j] = EMPTY_VALUE;
                continue;
            }

            matrix[i][i] = 1.0;

            for(int j = i + 1; j < count; j++)
            {
                double prices_j[];
                if(data.GetPriceData(symbols[j], timeframe, bars, prices_j) <= 0)
                {
                    matrix[i][j] = EMPTY_VALUE;
                    matrix[j][i] = EMPTY_VALUE;
                    continue;
                }

                int usable = MathMin(bars, MathMin(ArraySize(prices_i), ArraySize(prices_j)));
                if(usable <= 1)
                {
                    matrix[i][j] = EMPTY_VALUE;
                    matrix[j][i] = EMPTY_VALUE;
                    continue;
                }

                double corr = CalculateCorrelation(prices_i, prices_j, usable);
                matrix[i][j] = corr;
                matrix[j][i] = corr;
            }
        }

        return true;
    }

    /**
     * Builds a correlation matrix using the configured lookback bars.
     * @param matrix Output matrix.
     * @param symbols Symbol list.
     * @param timeframe Timeframe for calculation.
     * @param data Data manager for price retrieval.
     * @return true on success.
     */
    bool BuildMatrix(double &matrix[][],
                     const string &symbols[],
                     ENUM_TIMEFRAMES timeframe,
                     CDataManager &data)
    {
        return BuildMatrix(matrix, symbols, timeframe, data, m_lookback_bars);
    }

    /**
     * Builds a correlation matrix using direct price retrieval.
     * @param matrix Output matrix.
     * @param symbols Symbol list.
     * @param timeframe Timeframe for calculation.
     * @return true on success.
     */
    bool BuildMatrix(double &matrix[][],
                     const string &symbols[],
                     ENUM_TIMEFRAMES timeframe)
    {
        int count = ArraySize(symbols);
        if(count <= 0 || m_lookback_bars <= 1)
            return false;

        ArrayResize(matrix, count);
        for(int i = 0; i < count; i++)
            ArrayResize(matrix[i], count);

        double prices[][];
        bool ok[];
        ArrayResize(prices, count);
        ArrayResize(ok, count);

        for(int i = 0; i < count; i++)
        {
            ArrayResize(prices[i], m_lookback_bars);
            ArraySetAsSeries(prices[i], true);
            ResetLastError();
            int copied = CopyClose(symbols[i], timeframe, 0, m_lookback_bars, prices[i]);
            ok[i] = (copied > 1);
            if(!ok[i])
            {
                int err = GetLastError();
                g_logger.Error(StringFormat(
                    "CorrelationEngine: CopyClose failed in BuildMatrix. symbol=%s, timeframe=%s, requested=%d, copied=%d, err=%d",
                    symbols[i], EnumToString(timeframe), m_lookback_bars, copied, err));
            }
        }

        for(int i = 0; i < count; i++)
        {
            if(!ok[i])
            {
                for(int j = 0; j < count; j++)
                    matrix[i][j] = EMPTY_VALUE;
                continue;
            }

            matrix[i][i] = 1.0;
            for(int j = i + 1; j < count; j++)
            {
                if(!ok[j])
                {
                    matrix[i][j] = EMPTY_VALUE;
                    matrix[j][i] = EMPTY_VALUE;
                    continue;
                }

                int usable = MathMin(m_lookback_bars, MathMin(ArraySize(prices[i]), ArraySize(prices[j])));
                if(usable <= 1)
                {
                    matrix[i][j] = EMPTY_VALUE;
                    matrix[j][i] = EMPTY_VALUE;
                    continue;
                }

                double corr = CalculateCorrelation(prices[i], prices[j], usable);
                matrix[i][j] = corr;
                matrix[j][i] = corr;
            }
        }

        return true;
    }
};
