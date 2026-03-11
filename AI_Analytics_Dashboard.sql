-- AI_Analytics_Dashboard.sql

-- This SQL script demonstrates advanced SQL patterns for AI-native products.

-- 1. Window Functions
-- Window functions allow us to perform calculations across a set of table rows that are somehow related to the current row.
-- For example, calculating the running total of sales:
SELECT 
    sales_date,
    amount,
    SUM(amount) OVER (ORDER BY sales_date) AS running_total
FROM 
    sales_data;

-- 2. Recursive CTEs
-- Common Table Expressions (CTEs) can be recursive, which is useful for querying hierarchical data.
WITH RECURSIVE sales_hierarchy AS (
    SELECT employee_id, manager_id, sales_amount
    FROM employees
    WHERE manager_id IS NULL
    UNION ALL
    SELECT e.employee_id, e.manager_id, e.sales_amount
    FROM employees e
    INNER JOIN sales_hierarchy sh ON e.manager_id = sh.employee_id
)
SELECT * FROM sales_hierarchy;

-- 3. Complex Aggregations
-- Advanced aggregations allow you to summarize data in meaningful ways. Here's an example of cohort analysis:
SELECT 
    cohort,
    COUNT(DISTINCT user_id) AS active_users,
    AVG(revenue) AS average_revenue
FROM 
    user_cohorts
GROUP BY cohort;

-- 4. Cohort Analysis
-- This part of the script demonstrates cohort analysis, which is critical for understanding user engagement over time.
-- It tracks user behavior in groups over several time periods.

-- 5. Transaction-safe Queries
-- Using transactions ensures that complex operations can be rolled back if something goes wrong.
BEGIN;
UPDATE accounts SET balance = balance - 100 WHERE account_id = 1;
UPDATE accounts SET balance = balance + 100 WHERE account_id = 2;
COMMIT;

-- 6. Performance-Optimized Approximate Queries
-- Approximate queries can help to improve performance when exact numbers aren't necessary. Example:
SELECT 
    APPROX_COUNT_DISTINCT(user_id) AS unique_users
FROM 
    user_engagement_data;

-- This script encompasses a variety of methods to analyze and manage data effectively for AI applications!