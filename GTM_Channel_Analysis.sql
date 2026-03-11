-- GTM Channel Analysis SQL script

-- This script analyzes various metrics for channels within the GTM framework including click rates, completion rates, violations, and GMV metrics.

-- Define CTEs to compute different metrics
WITH click_metrics AS (
    SELECT 
        channel,
        tier,
        api_status,
        COUNT(*) AS total_clicks,
        SUM(CASE WHEN action_completed = 1 THEN 1 ELSE 0 END) AS completed_actions,
        COUNT(*) * 1.0 / NULLIF(SUM(CASE WHEN action_completed = 1 THEN 1 ELSE 0 END), 0) AS click_through_rate
    FROM gtm_events
    GROUP BY channel, tier, api_status
),

completion_metrics AS (
    SELECT 
        channel,
        tier,
        COUNT(*) AS total_events,
        SUM(CASE WHEN action_completed = 1 THEN 1 ELSE 0 END) AS completed_events,
        COUNT(*) * 1.0 / NULLIF(SUM(CASE WHEN action_completed = 1 THEN 1 ELSE 0 END), 0) AS completion_rate
    FROM gtm_events
    GROUP BY channel, tier
),

violation_analysis AS (
    SELECT
        channel,
        COUNT(*) AS total_violations
    FROM gtm_events
    WHERE is_violation = 1
    GROUP BY channel
),

gmv_metrics AS (
    SELECT 
        channel,
        SUM(gmv) AS total_gmv
    FROM gtm_revenue
    GROUP BY channel
)

-- Combine results
SELECT 
    c.channel,
    c.tier,
    c.api_status,
    c.total_clicks,
    c.completed_actions,
    c.click_through_rate,
    cm.total_events,
    cm.completed_events,
    cm.completion_rate,
    va.total_violations,
    gm.total_gmv
FROM click_metrics c
LEFT JOIN completion_metrics cm ON c.channel = cm.channel AND c.tier = cm.tier
LEFT JOIN violation_analysis va ON c.channel = va.channel
LEFT JOIN gmv_metrics gm ON c.channel = gm.channel;