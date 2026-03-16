-- ============================================================================
-- Recursive CTE Example: Social Media User Activity Hierarchy
-- Analyzing active users within 10, 30, and 60 days with duration & activities
-- ============================================================================

-- Setup: Create sample tables
CREATE TABLE users (
    user_id INT PRIMARY KEY,
    username VARCHAR(100),
    created_at DATE,
    account_status VARCHAR(20)
);

CREATE TABLE user_sessions (
    session_id INT PRIMARY KEY,
    user_id INT,
    login_time TIMESTAMP,
    logout_time TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE TABLE user_activities (
    activity_id INT PRIMARY KEY,
    user_id INT,
    session_id INT,
    activity_type VARCHAR(50),  -- 'post', 'like', 'comment', 'share', 'view'
    activity_timestamp TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (session_id) REFERENCES user_sessions(session_id)
);

-- ============================================================================
-- RECURSIVE CTE APPROACH: Build user activity hierarchy
-- ============================================================================

WITH RECURSIVE user_activity_hierarchy AS (
    -- BASE CASE: Get all users with their most recent login
    SELECT
        u.user_id,
        u.username,
        u.created_at,
        us.session_id,
        us.login_time,
        us.logout_time,
        EXTRACT(EPOCH FROM (us.logout_time - us.login_time)) / 60 AS session_duration_minutes,
        DATEDIFF(DAY, us.login_time, CURRENT_TIMESTAMP) AS days_since_login,
        1 AS recursion_level,
        ARRAY[u.user_id] AS user_path  -- Track traversal path
    FROM
        users u
    LEFT JOIN
        user_sessions us ON u.user_id = us.user_id
    WHERE
        u.account_status = 'active'
        AND us.login_time IS NOT NULL
        AND DATEDIFF(DAY, us.login_time, CURRENT_TIMESTAMP) <= 60
    
    UNION ALL
    
    -- RECURSIVE CASE: Aggregate activities for each session
    SELECT
        uah.user_id,
        uah.username,
        uah.created_at,
        uah.session_id,
        uah.login_time,
        uah.logout_time,
        uah.session_duration_minutes,
        uah.days_since_login,
        uah.recursion_level + 1,
        uah.user_path || uah.user_id  -- Append to path
    FROM
        user_activity_hierarchy uah
    INNER JOIN
        user_activities ua ON uah.session_id = ua.session_id
    WHERE
        uah.recursion_level < 3  -- Limit recursion depth to prevent infinite loops
)

-- Final query using the recursive CTE
SELECT
    user_id,
    username,
    created_at,
    CASE
        WHEN days_since_login <= 10 THEN '0-10 Days (Hot Users)'
        WHEN days_since_login <= 30 THEN '11-30 Days (Active Users)'
        WHEN days_since_login <= 60 THEN '31-60 Days (Returning Users)'
        ELSE 'Inactive'
    END AS activity_bucket,
    COUNT(DISTINCT session_id) AS total_sessions,
    ROUND(AVG(session_duration_minutes), 2) AS avg_session_duration_minutes,
    MAX(days_since_login) AS days_since_last_login,
    recursion_level AS hierarchy_depth
FROM
    user_activity_hierarchy
GROUP BY
    user_id,
    username,
    created_at,
    days_since_login,
    recursion_level
ORDER BY
    days_since_login ASC,
    total_sessions DESC;

-- ============================================================================
-- ADVANCED: Recursive CTE with Activity Aggregation by Type
-- ============================================================================

WITH RECURSIVE session_activity_tree AS (
    -- BASE: Get sessions and their initial activity counts
    SELECT
        us.session_id,
        u.user_id,
        u.username,
        us.login_time,
        us.logout_time,
        EXTRACT(EPOCH FROM (us.logout_time - us.login_time)) / 60 AS session_duration_minutes,
        DATEDIFF(DAY, us.login_time, CURRENT_TIMESTAMP) AS days_since_login,
        COUNT(CASE WHEN ua.activity_type = 'post' THEN 1 END) AS post_count,
        COUNT(CASE WHEN ua.activity_type = 'like' THEN 1 END) AS like_count,
        COUNT(CASE WHEN ua.activity_type = 'comment' THEN 1 END) AS comment_count,
        COUNT(CASE WHEN ua.activity_type = 'share' THEN 1 END) AS share_count,
        COUNT(CASE WHEN ua.activity_type = 'view' THEN 1 END) AS view_count,
        COUNT(ua.activity_id) AS total_activities,
        1 AS depth_level
    FROM
        user_sessions us
    INNER JOIN
        users u ON us.user_id = u.user_id
    LEFT JOIN
        user_activities ua ON us.session_id = ua.session_id
    WHERE
        u.account_status = 'active'
        AND DATEDIFF(DAY, us.login_time, CURRENT_TIMESTAMP) <= 60
    GROUP BY
        us.session_id,
        u.user_id,
        u.username,
        us.login_time,
        us.logout_time,
        session_duration_minutes
    
    UNION ALL
    
    -- RECURSIVE: Accumulate metrics across multiple sessions per user
    SELECT
        sat.session_id,
        sat.user_id,
        sat.username,
        sat.login_time,
        sat.logout_time,
        sat.session_duration_minutes,
        sat.days_since_login,
        sat.post_count,
        sat.like_count,
        sat.comment_count,
        sat.share_count,
        sat.view_count,
        sat.total_activities,
        sat.depth_level + 1
    FROM
        session_activity_tree sat
    WHERE
        sat.depth_level < 5  -- Prevent infinite recursion
)

SELECT
    user_id,
    username,
    CASE
        WHEN days_since_login <= 10 THEN '0-10 Days (Hot Users)'
        WHEN days_since_login <= 30 THEN '11-30 Days (Active Users)'
        ELSE '31-60 Days (Returning Users)'
    END AS user_segment,
    COUNT(DISTINCT session_id) AS total_sessions,
    ROUND(AVG(session_duration_minutes), 2) AS avg_session_duration_min,
    SUM(post_count) AS total_posts,
    SUM(like_count) AS total_likes,
    SUM(comment_count) AS total_comments,
    SUM(share_count) AS total_shares,
    SUM(view_count) AS total_views,
    SUM(total_activities) AS total_actions,
    ROUND(SUM(total_activities) / NULLIF(COUNT(DISTINCT session_id), 0), 2) AS avg_actions_per_session
FROM
    session_activity_tree
GROUP BY
    user_id,
    username,
    user_segment
ORDER BY
    CASE
        WHEN user_segment = '0-10 Days (Hot Users)' THEN 1
        WHEN user_segment = '11-30 Days (Active Users)' THEN 2
        ELSE 3
    END,
    total_actions DESC;

-- ============================================================================
-- BONUS: Recursive CTE for User Engagement Level Hierarchy
-- ============================================================================

WITH RECURSIVE engagement_hierarchy AS (
    -- Level 0: Super Users (10+ actions in last 10 days)
    SELECT
        u.user_id,
        u.username,
        'Level 0: Super Users' AS engagement_level,
        COUNT(ua.activity_id) AS activity_count,
        0 AS hierarchy_level
    FROM
        users u
    INNER JOIN
        user_sessions us ON u.user_id = us.user_id
    INNER JOIN
        user_activities ua ON us.session_id = ua.session_id
    WHERE
        u.account_status = 'active'
        AND DATEDIFF(DAY, ua.activity_timestamp, CURRENT_TIMESTAMP) <= 10
    GROUP BY
        u.user_id,
        u.username
    HAVING
        COUNT(ua.activity_id) >= 10
    
    UNION ALL
    
    -- Level 1: Active Users (3-9 actions in last 30 days)
    SELECT
        u.user_id,
        u.username,
        'Level 1: Active Users' AS engagement_level,
        COUNT(ua.activity_id) AS activity_count,
        eh.hierarchy_level + 1
    FROM
        users u
    INNER JOIN
        user_sessions us ON u.user_id = us.user_id
    INNER JOIN
        user_activities ua ON us.session_id = ua.session_id
    CROSS JOIN
        engagement_hierarchy eh
    WHERE
        u.account_status = 'active'
        AND DATEDIFF(DAY, ua.activity_timestamp, CURRENT_TIMESTAMP) <= 30
        AND u.user_id NOT IN (SELECT user_id FROM engagement_hierarchy)
    GROUP BY
        u.user_id,
        u.username,
        eh.hierarchy_level
    HAVING
        COUNT(ua.activity_id) BETWEEN 3 AND 9
)

SELECT
    user_id,
    username,
    engagement_level,
    activity_count,
    hierarchy_level
FROM
    engagement_hierarchy
ORDER BY
    hierarchy_level ASC,
    activity_count DESC;