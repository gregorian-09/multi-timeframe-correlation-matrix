#pragma once

// Global constants for the correlation matrix project.

#define CORRELATION_PREFIX     "CORR_"  // Object name prefix
#define MAX_SYMBOLS            15       // Maximum symbols
#define MAX_TIMEFRAMES         9        // Maximum timeframes
#define DEFAULT_LOOKBACK       100      // Default bar count
#define DEFAULT_CELL_SIZE      40       // Default cell pixels
#define DEFAULT_COOLDOWN       300      // Alert cooldown (seconds)
#define DEFAULT_CACHE_SECONDS  60       // Data cache refresh interval

/**
 * Error codes for common failure scenarios.
 */
enum ENUM_ERROR_CODE
{
    ERR_NONE = 0,
    ERR_INVALID_SYMBOL = 1,
    ERR_NO_DATA = 2,
    ERR_CALC_FAILED = 3,
    ERR_DISPLAY_FAILED = 4,
    ERR_ALERT_FAILED = 5
};
