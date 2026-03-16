-- Advanced CSAT and Comprehension Rate Analysis
-- Segmentation by Seller Tier, Risk Level, Region, and Product Category

SELECT 
    seller_tier, 
    risk_level, 
    region, 
    product_category, 
    AVG(csat_score) AS average_csat, 
    AVG(comprehension_rate) AS average_comprehension_rate
FROM 
    customer_feedback
WHERE 
    feedback_date >= '2023-01-01' 
GROUP BY 
    seller_tier, risk_level, region, product_category 
ORDER BY 
    seller_tier, risk_level, region, product_category;