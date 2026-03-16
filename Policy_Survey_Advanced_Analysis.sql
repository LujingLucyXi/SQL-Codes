-- ============================================================================
-- ADVANCED CSAT AND COMPREHENSION RATE METRICS
-- ============================================================================

WITH metrics AS (
  SELECT
    s.seller_tier,
    s.risk_level,
    s.region,
    s.product_category,
    
    -- Total unique survey takers per segment
    COUNT(DISTINCT s.user_id) AS total_users,
    
    -- Distinct satisfied users (thumbs_up)
    COUNT(DISTINCT CASE WHEN s.satisfaction_rating = 'thumbs_up' THEN s.user_id END) AS satisfied_users,
    
    -- Distinct thumbs_down users with policy concerns (not comprehension issues)
    COUNT(DISTINCT CASE 
      WHEN s.satisfaction_rating = 'thumbs_down' 
        AND f.followup_response IN (
          'I do not agree with the policy',
          'I think the enforcement is too severe',
          'I am not happy with the enforcement process'
        )
      THEN s.user_id 
    END) AS policy_concern_users,
    
    -- Users with comprehension issues (hard to understand)
    COUNT(DISTINCT CASE 
      WHEN s.satisfaction_rating = 'thumbs_down' 
        AND f.followup_response IN (
          'The policy was hard to understand',
          'The violation ticket did not clearly indicate what I did wrong'
        )
      THEN s.user_id 
    END) AS comprehension_issue_users,
    
    -- Neutral/Other responses
    COUNT(DISTINCT CASE 
      WHEN s.satisfaction_rating = 'thumbs_down' 
        AND f.followup_response NOT IN (
          'I do not agree with the policy',
          'I think the enforcement is too severe',
          'I am not happy with the enforcement process',
          'The policy was hard to understand',
          'The violation ticket did not clearly indicate what I did wrong'
        )
      THEN s.user_id 
    END) AS other_concern_users,
    
    -- Trend metrics
    COUNT(DISTINCT CASE WHEN s.created_at >= CURRENT_DATE - INTERVAL '7 days' 
      AND s.satisfaction_rating = 'thumbs_up' THEN s.user_id END) AS recent_satisfied_users,
    
    COUNT(DISTINCT CASE WHEN s.created_at >= CURRENT_DATE - INTERVAL '7 days' THEN s.user_id END) AS recent_total_users,
    
    -- Response rate (surveys that have follow-up responses)
    COUNT(DISTINCT CASE WHEN f.user_id IS NOT NULL THEN s.user_id END) AS users_with_followup,
    
    -- Survey count and repeat survey takers
    COUNT(s.survey_id) AS total_surveys,
    COUNT(DISTINCT s.survey_id) AS distinct_surveys,
    MAX(s.created_at) AS last_survey_date,
    MIN(s.created_at) AS first_survey_date
    
  FROM satisfaction_surveys s
  LEFT JOIN survey_followup_responses f
    ON s.user_id = f.user_id
    AND s.survey_id = f.survey_id
  
  GROUP BY s.seller_tier, s.risk_level, s.region, s.product_category
),

metrics_with_calculations AS (
  SELECT
    seller_tier,
    risk_level,
    region,
    product_category,
    total_users,
    satisfied_users,
    policy_concern_users,
    comprehension_issue_users,
    other_concern_users,
    recent_satisfied_users,
    recent_total_users,
    users_with_followup,
    total_surveys,
    distinct_surveys,
    last_survey_date,
    first_survey_date,
    
    -- Core metrics
    ROUND((satisfied_users * 100.0) / NULLIF(total_users, 0), 2) AS csat_percentage,
    ROUND(((satisfied_users + policy_concern_users) * 100.0) / NULLIF(total_users, 0), 2) AS comprehension_percentage,
    
    -- Additional insights
    ROUND((users_with_followup * 100.0) / NULLIF(total_users, 0), 2) AS followup_response_rate,
    ROUND((comprehension_issue_users * 100.0) / NULLIF(total_users, 0), 2) AS comprehension_issue_rate,
    ROUND((policy_concern_users * 100.0) / NULLIF(total_users, 0), 2) AS policy_concern_rate,
    ROUND((other_concern_users * 100.0) / NULLIF(total_users, 0), 2) AS other_concern_rate,
    
    -- Recent trend (7-day)
    ROUND((recent_satisfied_users * 100.0) / NULLIF(recent_total_users, 0), 2) AS recent_csat_7day,
    
    -- Repeat survey indicator
    ROUND((total_surveys * 1.0) / NULLIF(distinct_surveys, 0), 2) AS avg_surveys_per_user,
    
    -- Days active
    DATEDIFF(DAY, first_survey_date, last_survey_date) AS days_active_in_survey,
    
    -- Risk score (composite)
    CASE 
      WHEN (satisfied_users * 100.0 / NULLIF(total_users, 0)) >= 80 
        AND (comprehension_issue_users * 100.0 / NULLIF(total_users, 0)) < 5 
      THEN 'Low Risk'
      WHEN (satisfied_users * 100.0 / NULLIF(total_users, 0)) >= 70 
        AND (comprehension_issue_users * 100.0 / NULLIF(total_users, 0)) < 10 
      THEN 'Medium Risk'
      ELSE 'High Risk'
    END AS satisfaction_risk_score
    
  FROM metrics
),

segment_rankings AS (
  SELECT
    *,
    -- Ranking within each tier
    ROW_NUMBER() OVER (PARTITION BY seller_tier, risk_level ORDER BY csat_percentage DESC) AS csat_rank_in_segment,
    
    -- Percentile ranking across all segments
    PERCENT_RANK() OVER (ORDER BY csat_percentage) AS csat_percentile,
    PERCENT_RANK() OVER (ORDER BY comprehension_percentage) AS comprehension_percentile
  FROM metrics_with_calculations
)

SELECT
  seller_tier,
  risk_level,
  region,
  product_category,
  
  -- Core Metrics
  csat_percentage,
  comprehension_percentage,
  
  -- Breakdown Metrics
  satisfied_users,
  policy_concern_users,
  comprehension_issue_users,
  other_concern_users,
  total_users,
  
  -- Response & Engagement
  followup_response_rate,
  users_with_followup,
  avg_surveys_per_user,
  
  -- Issue Rates
  comprehension_issue_rate,
  policy_concern_rate,
  other_concern_rate,
  
  -- Trend Metrics
  recent_csat_7day,
  
  -- Activity Metrics
  days_active_in_survey,
  last_survey_date,
  
  -- Risk & Rankings
  satisfaction_risk_score,
  csat_rank_in_segment,
  ROUND(csat_percentile * 100, 2) AS csat_percentile_score,
  ROUND(comprehension_percentile * 100, 2) AS comprehension_percentile_score

FROM segment_rankings
ORDER BY 
  CASE 
    WHEN seller_tier = 'T1' THEN 1
    WHEN seller_tier = 'T2' THEN 2
    WHEN seller_tier = 'T3' THEN 3
    WHEN seller_tier = 'T4' THEN 4
    WHEN seller_tier = 'T5' THEN 5
    WHEN seller_tier = 'T6' THEN 6
    ELSE 7
  END,
  CASE 
    WHEN risk_level = 'low' THEN 1
    WHEN risk_level = 'medium' THEN 2
    WHEN risk_level = 'high' THEN 3
    ELSE 4
  END,
  csat_percentage DESC;