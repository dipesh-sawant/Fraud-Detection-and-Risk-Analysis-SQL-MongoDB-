-- ====================================================================================================
-- Customer Risk Analysis: 
-- Identify customers with low credit scores and high-risk loans to predict potential defaults and prioritize risk mitigation strategies.
-- ----------------------------------------------------------------------------------------------------
SELECT DISTINCT
    c.customer_id,
    c.name,
    c.credit_score,
    l.default_risk
FROM
    customer_table c
JOIN
    loan_table l
ON
    c.customer_id = l.customer_id
WHERE
    c.credit_score < 600
    AND
    l.default_risk = 'High'
ORDER BY
    c.credit_score ASC;
-- ====================================================================================================
-- Loan Purpose Insights: 
-- Determine the most popular loan purposes and their associated revenues to align financial products with customer demands
-- ----------------------------------------------------------------------------------------------------
SELECT 
    l.loan_purpose, 
    COUNT(l.loan_purpose) AS No_of_Loans, 
    AVG(l.loan_amount) AS Avg_Loan_Amt, 
    AVG(t.transaction_amount) AS Avg_Trn_Amt
FROM 
    loan_table AS l
JOIN 
    transaction_table AS t 
ON 
    l.loan_id = t.loan_id
GROUP BY 
    l.loan_purpose
ORDER BY 
    No_of_Loans DESC;
-- ====================================================================================================
-- High-Value Transactions:
-- Detect transactions that exceed 30% of their respective loan amounts to flag potential fraudulent activities
-- ----------------------------------------------------------------------------------------------------
SELECT
	c.customer_id,
    c.name,
    l.loan_id,
    t.transaction_id,
    l.loan_amount,
    t.transaction_amount,
    t.transaction_amount/l.loan_amount*100 AS "trans_to_loan_percent"
FROM
	customer_table AS c
JOIN
	loan_table AS l 
ON
	c.customer_id = l.customer_id
JOIN
    transaction_table AS t
ON
	l.loan_id = t.loan_id
WHERE
	t.status = "Successful"
    AND
    t.transaction_amount > 0.3 * l.loan_amount
ORDER BY
	trans_to_loan_percent DESC;
-- ====================================================================================================
-- Missed EMI Count:
-- Analyze the number of missed EMIs per loan to identify loans at risk of default and suggest intervention strategies
-- ----------------------------------------------------------------------------------------------------
SELECT 
    l.loan_id,
    c.customer_id,
    CASE 
        WHEN MAX(CASE default_risk WHEN 'High' THEN 3 WHEN 'Medium' THEN 2 WHEN 'Low' THEN 1 END) = 3 THEN 'High'
        WHEN MAX(CASE default_risk WHEN 'High' THEN 3 WHEN 'Medium' THEN 2 WHEN 'Low' THEN 1 END) = 2 THEN 'Medium'
        WHEN MAX(CASE default_risk WHEN 'High' THEN 3 WHEN 'Medium' THEN 2 WHEN 'Low' THEN 1 END) = 1 THEN 'Low'
    END AS default_risk,
    ROUND(AVG(l.loan_amount),0) AS avg_loan_amount,
    COUNT(t.transaction_id) AS missed_emis
FROM 
    loan_table AS l
JOIN 
    transaction_table AS t 
ON 
    l.loan_id = t.loan_id
JOIN 
    customer_table AS c 
ON 
    l.customer_id = c.customer_id
WHERE 
    t.transaction_type = 'Missed EMI' -- Assuming there's a specific type for missed EMI
GROUP BY 
    l.loan_id, c.customer_id
HAVING 
    missed_emis > 0
ORDER BY 
    missed_emis DESC;
-- ====================================================================================================
-- Regional Loan Distribution:
-- Examine the geographical distribution of loan disbursements to assess regional trends and business opportunities. 
-- ----------------------------------------------------------------------------------------------------
SELECT
    SUBSTRING_INDEX(c.address, ',', -1) AS region, -- Extract the region (e.g., state or country) from the address
    COUNT(l.loan_id) AS total_loans,
    SUM(l.loan_amount) AS total_loan_disbursement,
    ROUND(AVG(l.loan_amount), 2) AS avg_loan_amount
FROM
    customer_table AS c
JOIN
    loan_table AS l
ON
    c.customer_id = l.customer_id
GROUP BY
    region
ORDER BY
    total_loan_disbursement DESC;
-- ====================================================================================================
-- Loyal Customers:
-- List customers who have been associated with Cross River Bank for over five years and evaluate their loan activity to design loyalty programs.
-- ----------------------------------------------------------------------------------------------------
SELECT 
    c.customer_id,
    c.name,
    c.customer_since,
    COUNT(l.loan_id) AS total_loans,
    SUM(l.loan_amount) AS total_loan_disbursed,
    ROUND(AVG(l.default_risk = 'Low'), 2) AS loyalty_score
FROM 
    customer_table AS c
LEFT JOIN 
    loan_table AS l
ON 
    c.customer_id = l.customer_id
WHERE 
    DATEDIFF(CURDATE(), STR_TO_DATE(c.customer_since, '%m/%d/%Y')) > 5 * 365
GROUP BY 
    c.customer_id, c.name, c.customer_since
ORDER BY 
    loyalty_score DESC, total_loan_disbursed DESC;
-- ====================================================================================================
-- High-Performing Loans:
-- Identify loans with excellent repayment histories to refine lending policies and highlight successful products.
-- ----------------------------------------------------------------------------------------------------
SELECT 
    l.loan_id,
    c.customer_id,
    c.name AS customer_name,
    l.loan_amount,
    l.loan_purpose,
    COUNT(t.transaction_id) AS total_transactions,
    SUM(CASE WHEN t.transaction_type = 'EMI Payment' AND t.status = 'Successful' THEN 1 ELSE 0 END) AS successful_emi_payments,
    SUM(CASE WHEN t.transaction_type = 'Missed EMI' THEN 1 ELSE 0 END) AS missed_emi_count,
    SUM(CASE WHEN t.transaction_type = 'Prepayment' THEN 1 ELSE 0 END) AS prepayments,
    ROUND(AVG(l.default_risk = 'Low'), 2) AS excellent_risk_score
FROM 
    loan_table AS l
JOIN 
    transaction_table AS t 
ON 
    l.loan_id = t.loan_id
JOIN 
    customer_table AS c 
ON 
    l.customer_id = c.customer_id
WHERE 
    l.default_risk = 'Low' -- Consider only loans with "Low" risk
GROUP BY 
    l.loan_id, c.customer_id, c.name, l.loan_amount, l.loan_purpose
HAVING 
    missed_emi_count = 0 -- No missed EMI
    AND successful_emi_payments > 0 -- At least one successful EMI payment
ORDER BY 
    excellent_risk_score DESC, successful_emi_payments DESC, l.loan_amount DESC;
-- ====================================================================================================
-- Age-Based Loan Analysis:
-- Analyze loan amounts disbursed to customers of different age groups to design targeted financial products.
-- ----------------------------------------------------------------------------------------------------
SELECT 
    CASE
        WHEN c.age < 25 THEN '<25'
        WHEN c.age BETWEEN 25 AND 34 THEN '25-34'
        WHEN c.age BETWEEN 35 AND 44 THEN '35-44'
        WHEN c.age BETWEEN 45 AND 54 THEN '45-54'
        ELSE '55+'
    END AS age_group,
    COUNT(l.loan_id) AS total_loans,
    SUM(l.loan_amount) AS total_loan_disbursed,
    ROUND(AVG(l.loan_amount), 2) AS avg_loan_amount
FROM 
    customer_table AS c
JOIN 
    loan_table AS l
ON 
    c.customer_id = l.customer_id
GROUP BY 
    age_group
ORDER BY 
    total_loan_disbursed DESC;
-- ====================================================================================================
-- Seasonal Transaction Trends:
-- Examine transaction patterns over years and months to identify seasonal trends in loan repayments.
-- ----------------------------------------------------------------------------------------------------
SELECT 
    YEAR(STR_TO_DATE(t.transaction_date, '%m/%d/%Y')) AS transaction_year,
    MONTH(STR_TO_DATE(t.transaction_date, '%m/%d/%Y')) AS transaction_month,
    COUNT(CASE WHEN t.transaction_type = 'EMI Payment' AND t.status = 'Successful' THEN 1 ELSE NULL END) AS count_emi_payment,
    COUNT(CASE WHEN t.transaction_type = 'Missed EMI' AND t.status = 'Successful' THEN 1 ELSE NULL END) AS count_missed_emi,
    COUNT(CASE WHEN t.transaction_type = 'Prepayment' AND t.status = 'Successful' THEN 1 ELSE NULL END) AS count_prepayment,
    COUNT(CASE WHEN t.status = 'Successful' THEN 1 ELSE NULL END) AS count_all_transactions
FROM 
    transaction_table AS t
WHERE 
    t.transaction_type IN ('EMI Payment', 'Missed EMI', 'Prepayment') -- Focus on specific transaction types
GROUP BY 
    transaction_year, transaction_month
ORDER BY 
    transaction_year, transaction_month;
-- ====================================================================================================
-- Fraud Detection:
-- Highlight potential fraud by identifying mismatches between customer address locations and transaction IP locationsbehavior_logs.
-- ----------------------------------------------------------------------------------------------------
SELECT 
    t.transaction_id,
    t.transaction_date,
    t.transaction_amount,
    c.customer_id,
    c.name AS customer_name,
    c.address AS customer_address,
    b.location AS transaction_location,
    'Fraud Suspected' AS fraud_status
FROM 
    transaction_table AS t
JOIN 
    customer_table AS c ON t.customer_id = c.customer_id
JOIN 
    behavior_logs AS b ON b.customer_id = t.customer_id -- Use exported JSON mismatch data
WHERE 
    t.status = 'Successful';
-- ====================================================================================================
-- Repayment History Analysis: 
-- Rank loans by repayment performance using window functions.
-- ----------------------------------------------------------------------------------------------------
SELECT 
    l.loan_id,
    l.loan_amount,
    COUNT(CASE WHEN t.transaction_type = 'EMI Payment' AND t.status = 'Successful' THEN t.transaction_id END) AS successful_emi_payments,
    COUNT(CASE WHEN t.transaction_type = 'Missed EMI' AND t.status = 'Successful' THEN t.transaction_id END) AS successful_missed_emis,
    COUNT(CASE WHEN t.transaction_type = 'Prepayment' AND t.status = 'Successful' THEN t.transaction_id END) AS successful_prepayments,
    SUM(CASE WHEN t.transaction_type = 'EMI Payment' AND t.status = 'Successful' THEN t.transaction_amount ELSE 0 END) AS total_emi_payment_amount,
    SUM(CASE WHEN t.transaction_type = 'Prepayment' AND t.status = 'Successful' THEN t.transaction_amount ELSE 0 END) AS total_prepayment_amount,
    RANK() OVER (
        ORDER BY 
            COUNT(CASE WHEN t.transaction_type = 'EMI Payment' AND t.status = 'Successful' THEN t.transaction_id END) DESC, -- Rank by most successful EMI payments
            SUM(CASE WHEN t.transaction_type = 'EMI Payment' AND t.status = 'Successful' THEN t.transaction_amount ELSE 0 END) DESC, -- Then by EMI payment amount
            COUNT(CASE WHEN t.transaction_type = 'Missed EMI' AND t.status = 'Successful' THEN t.transaction_id END) ASC -- Penalize loans with missed EMIs
    ) AS repayment_rank
FROM 
    loan_table AS l
LEFT JOIN 
    transaction_table AS t
ON 
    l.loan_id = t.loan_id
GROUP BY 
    l.loan_id, l.loan_amount
ORDER BY 
    repayment_rank;
-- ====================================================================================================
-- Credit Score vs. Loan Amount: 
-- Compare average loan amounts for different credit score ranges.
-- ----------------------------------------------------------------------------------------------------
SELECT 
    CASE
        WHEN c.credit_score < 600 THEN '<600'
        WHEN c.credit_score BETWEEN 600 AND 699 THEN '600-699'
        WHEN c.credit_score BETWEEN 700 AND 799 THEN '700-799'
        ELSE '800+'
    END AS credit_score_range,
    COUNT(l.loan_id) AS total_loans,
    ROUND(AVG(l.loan_amount), 2) AS avg_loan_amount
FROM 
    customer_table AS c
JOIN 
    loan_table AS l
ON 
    c.customer_id = l.customer_id
GROUP BY 
    credit_score_range
ORDER BY 
    credit_score_range;
-- ====================================================================================================
-- Top Borrowing Regions: 
-- Identify regions with the highest total loan disbursements.
-- ----------------------------------------------------------------------------------------------------
SELECT 
    SUBSTRING_INDEX(c.address, ',', -1) AS region, -- Extract the region (e.g., country or state) from the customer address
    COUNT(l.loan_id) AS total_loans,
    SUM(l.loan_amount) AS total_loan_disbursement,
    ROUND(AVG(l.loan_amount), 2) AS avg_loan_amount
FROM 
    customer_table AS c
JOIN 
    loan_table AS l
ON 
    c.customer_id = l.customer_id
GROUP BY 
    region
ORDER BY 
    total_loan_disbursement DESC
LIMIT 10; -- Display the top 10 regions
-- ====================================================================================================
-- Early Repayment Patterns: 
-- Detect loans with frequent early repayments and their impact on revenue.
-- ----------------------------------------------------------------------------------------------------
SELECT 
    l.loan_id,
    l.loan_amount,
    c.customer_id,
    c.name AS customer_name,
    COUNT(CASE WHEN t.transaction_type = 'Prepayment' AND t.status = 'Successful' THEN t.transaction_id END) AS prepayment_count,
    SUM(CASE WHEN t.transaction_type = 'Prepayment' AND t.status = 'Successful' THEN t.transaction_amount ELSE 0 END) AS total_prepayment_amount,
    ROUND((SUM(CASE WHEN t.transaction_type = 'Prepayment' AND t.status = 'Successful' THEN t.transaction_amount ELSE 0 END) / l.loan_amount) * 100, 2) AS prepayment_percentage
FROM 
    loan_table AS l
JOIN 
    customer_table AS c ON l.customer_id = c.customer_id
LEFT JOIN 
    transaction_table AS t ON l.loan_id = t.loan_id
GROUP BY 
    l.loan_id, c.customer_id, c.name, l.loan_amount
HAVING 
    prepayment_count > 0 -- Only include loans with prepayments
ORDER BY 
    prepayment_percentage DESC, prepayment_count DESC;
-- ====================================================================================================
-- Feedback Correlation: 
-- Correlate customer feedback sentiment scores with loan statuses.
-- ----------------------------------------------------------------------------------------------------
SELECT 
    l.loan_status,
    COUNT(f.feedback_text) AS total_feedbacks,
    ROUND(AVG(f.sentiment_score), 2) AS avg_sentiment_score,
    SUM(CASE WHEN f.sentiment_score > 0 THEN 1 ELSE 0 END) AS positive_feedback_count,
    SUM(CASE WHEN f.sentiment_score < 0 THEN 1 ELSE 0 END) AS negative_feedback_count
FROM 
    loan_table AS l
JOIN 
    customer_feedback AS f ON l.loan_id = f.loan_id
GROUP BY 
    l.loan_status
ORDER BY 
    avg_sentiment_score DESC;
-- ====================================================================================================
