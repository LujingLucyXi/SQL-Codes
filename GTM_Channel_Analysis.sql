-- GTM Channel Analysis SQL Script

-- This script performs a comprehensive analysis of GTM channel strength, analyzing key metrics such as click rates by channel and seller tier, action completion rates, violation rates, and GMV metrics.

-- Assuming we have the following tables:
-- - channel_data: contains channel interactions data
-- - seller_data: contains seller tier information

SELECT
    c.channel_name,
    s.seller_tier,
    COUNT(c.click_id) AS total_clicks,
    COUNT(CASE WHEN c.action_completed = 'yes' THEN 1 END) AS completed_actions,
    COUNT(CASE WHEN c.violation_occurred = 'yes' THEN 1 END) AS violation_count,
    SUM(c.gmv) AS total_gmv,
    (COUNT(c.click_id) / NULLIF(SUM(c.impressions), 0)) * 100 AS click_rate,
    (COUNT(CASE WHEN c.action_completed = 'yes' THEN 1 END) / NULLIF(COUNT(c.click_id), 0)) * 100 AS action_completion_rate,
    (COUNT(CASE WHEN c.violation_occurred = 'yes' THEN 1 END) / NULLIF(COUNT(c.click_id), 0)) * 100 AS violation_rate
FROM
    channel_data c
JOIN
    seller_data s ON c.seller_id = s.seller_id
GROUP BY
    c.channel_name,
    s.seller_tier
ORDER BY
    c.channel_name,
    s.seller_tier;
