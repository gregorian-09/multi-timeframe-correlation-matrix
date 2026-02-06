#pragma once

/**
 * Lightweight runtime log levels for operational telemetry.
 */
enum ENUM_LOG_LEVEL
{
    LOG_OFF = 0,
    LOG_ERROR = 1,
    LOG_DEBUG = 2
};

/**
 * Minimal logger that gates terminal Print calls by severity.
 */
class CLogger
{
private:
    ENUM_LOG_LEVEL m_level;

public:
    CLogger() : m_level(LOG_ERROR) {}

    void SetLevel(ENUM_LOG_LEVEL level)
    {
        m_level = level;
    }

    ENUM_LOG_LEVEL GetLevel() const
    {
        return m_level;
    }

    void Error(const string message) const
    {
        if(m_level >= LOG_ERROR)
            Print("[ERROR] ", message);
    }

    void Debug(const string message) const
    {
        if(m_level >= LOG_DEBUG)
            Print("[DEBUG] ", message);
    }
};

// One logger instance per compiled script/indicator unit.
CLogger g_logger;
