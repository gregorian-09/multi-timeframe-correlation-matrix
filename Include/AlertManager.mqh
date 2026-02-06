#pragma once

// Alert manager for divergence and threshold notifications.

#include <Constants.mqh>

/**
 * Alert categories.
 */
enum ENUM_ALERT_TYPE
{
    ALERT_DIVERGENCE,
    ALERT_THRESHOLD,
    ALERT_RECOVERY,
    ALERT_BREAKDOWN
};

/**
 * Tracks last sent time for a key.
 */
struct AlertState
{
    string key;
    datetime last_sent;
};

/**
 * Sends alerts with cooldown protection.
 */
class CAlertManager
{
private:
    bool m_enable_push;
    bool m_enable_email;
    bool m_enable_sound;
    int m_cooldown_seconds;
    AlertState m_states[];

    /**
     * Finds alert state index by key.
     * @param key Alert key.
     * @return Index or -1.
     */
    int FindStateIndex(const string key) const
    {
        for(int i = 0; i < ArraySize(m_states); i++)
        {
            if(m_states[i].key == key)
                return i;
        }
        return -1;
    }

    /**
     * Returns true if cooldown has elapsed for the key.
     * @param key Alert key.
     * @return true if alert can be sent.
     */
    bool CanSend(const string key)
    {
        int idx = FindStateIndex(key);
        if(idx < 0)
        {
            int size = ArraySize(m_states);
            ArrayResize(m_states, size + 1);
            m_states[size].key = key;
            m_states[size].last_sent = 0;
            return true;
        }

        datetime now = TimeCurrent();
        if((now - m_states[idx].last_sent) >= m_cooldown_seconds)
            return true;

        return false;
    }

    /**
     * Marks an alert as sent now.
     * @param key Alert key.
     * @return none
     */
    void MarkSent(const string key)
    {
        int idx = FindStateIndex(key);
        if(idx < 0)
            return;
        m_states[idx].last_sent = TimeCurrent();
    }

public:
    /**
     * Constructs manager with default preferences.
     * @return none
     */
    CAlertManager()
        : m_enable_push(true), m_enable_email(false), m_enable_sound(true), m_cooldown_seconds(DEFAULT_COOLDOWN) {}

    /**
     * Initializes alert preferences and cooldown.
     * @param enablePush Enable push notifications.
     * @param enableEmail Enable email alerts.
     * @param enableSound Enable sound alerts.
     * @param cooldownSeconds Cooldown seconds.
     * @return none
     */
    bool Initialize(bool enablePush, bool enableEmail, bool enableSound, int cooldownSeconds)
    {
        m_enable_push = enablePush;
        m_enable_email = enableEmail;
        m_enable_sound = enableSound;
        m_cooldown_seconds = cooldownSeconds;
        return true;
    }

    /**
     * Sets cooldown in seconds.
     * @param seconds Cooldown seconds.
     * @return none
     */
    void SetAlertCooldown(int seconds)
    {
        if(seconds < 0)
            seconds = 0;
        m_cooldown_seconds = seconds;
    }

    /**
     * Sets cooldown period between alerts.
     * @param seconds Cooldown seconds.
     * @return none
     */
    void SetCooldown(int seconds)
    {
        SetAlertCooldown(seconds);
    }

    /**
     * Evaluates whether an alert condition is met.
     * @param symbol1 First symbol.
     * @param symbol2 Second symbol.
     * @param oldCorr Previous correlation.
     * @param newCorr Current correlation.
     * @param threshold Threshold for alerting.
     * @return true if condition is met.
     */
    bool CheckAlertCondition(const string symbol1, const string symbol2,
                             double oldCorr, double newCorr, double threshold) const
    {
        // Symbols currently unused; kept for API compatibility and future logging.
        if(oldCorr == EMPTY_VALUE || newCorr == EMPTY_VALUE)
            return false;
        return MathAbs(newCorr - oldCorr) >= threshold;
    }

    /**
     * Checks if specific alert is in cooldown.
     * @param alertKey Alert key.
     * @return true if cooling down.
     */
    bool IsCoolingDown(const string alertKey) const
    {
        int idx = FindStateIndex(alertKey);
        if(idx < 0)
            return false;

        datetime now = TimeCurrent();
        return ((now - m_states[idx].last_sent) < m_cooldown_seconds);
    }

    /**
     * Sends an alert if cooldown allows.
     * @param message Alert message.
     * @param type Alert type.
     * @param key Alert key.
     * @return true if sent.
     */
    bool SendAlert(const string message, ENUM_ALERT_TYPE type, const string key)
    {
        if(!CanSend(key))
            return false;

        string prefix;
        switch(type)
        {
            case ALERT_DIVERGENCE: prefix = "Divergence"; break;
            case ALERT_THRESHOLD:  prefix = "Threshold"; break;
            case ALERT_RECOVERY:   prefix = "Recovery"; break;
            case ALERT_BREAKDOWN:  prefix = "Breakdown"; break;
            default: prefix = "Alert"; break;
        }

        string full = prefix + ": " + message;

        Alert(full);
        if(m_enable_sound)
            PlaySound("alert.wav");
        if(m_enable_push)
            SendNotification(full);
        if(m_enable_email)
            SendMail("Correlation Matrix", full);

        MarkSent(key);
        return true;
    }

    /**
     * Sends an alert using a generated key.
     * @param message Alert message.
     * @param type Alert type.
     * @return true if sent.
     */
    bool SendAlert(const string message, ENUM_ALERT_TYPE type)
    {
        string key = IntegerToString((int)type) + "_" + message;
        return SendAlert(message, type, key);
    }

    /**
     * Clears alert state.
     * @return none
     */
    void Cleanup()
    {
        ArrayResize(m_states, 0);
    }
};
