create database bank_crm;
use bank_crm;

/* 1) Distribution of account balances across different regions */
select ci.GeographyID ,
sum(b.balance) as distribution_balance
from bank_churn b
join customerinfo ci on b.CustomerID = ci.CustomerID
group by ci.GeographyID;

/* 2) top 5 customers with the highest Estimated Salary in the last quarter of the year. (SQL) */

SELECT 
    CustomerId,
    Surname,
    EstimatedSalary,
    Bank_DOJ
FROM 
    customerinfo
WHERE 
    MONTH(Bank_DOJ) IN (10, 11, 12)
ORDER BY 
    EstimatedSalary DESC
    LIMIT 5;

/* 3) average number of products used by customers who have a credit card */

SELECT
avg(NumOfProducts) as avg_products_with_creditcard
from bank_churn 
where HasCrCard = "1";

/* 4) Determine the churn rate by gender for the most recent year in the dataset.*/

WITH RecentYear AS (
    SELECT MAX(YEAR(Bank_DOJ)) AS MostRecentYear
    FROM CustomerInfo
)
SELECT 
    ci.GenderID,
    COUNT(*) AS total_customers,
    SUM(bc.Exited) AS churned_customers,
    ROUND(SUM(bc.Exited) * 100 / COUNT(*), 2) AS churn_rate_percent
FROM CustomerInfo ci
JOIN Bank_Churn bc 
    ON ci.CustomerId = bc.CustomerId
JOIN RecentYear r 
    ON YEAR(ci.Bank_DOJ) = r.MostRecentYear
GROUP BY ci.GenderID;

/* 5) Compare the average credit score of customers who have exited and those who remain */

SELECT 
Exited,
ROUND(AVG(CreditScore), 2) AS avg_credit_score,
COUNT(*) AS total_customers
FROM bank_churn
GROUP BY Exited;

/* 6) Which gender has a higher average estimated salary, and how does it relate to the number of active accounts? */

SELECT 
    c.GenderID,
    ROUND(AVG(c.EstimatedSalary), 2) AS AvgEstimatedSalary,
    COUNT(b.Exited) AS ActiveAccounts
FROM CustomerInfo c
JOIN Bank_Churn b 
    ON c.CustomerId = b.CustomerId
WHERE b.Exited = "0"
GROUP BY c.GenderID
ORDER BY AvgEstimatedSalary DESC;

/* 7) Segment the customers based on their credit score and identify the segment with the highest exit rate. */

SELECT CASE
        WHEN CreditScore < 600 THEN 'Low'
        WHEN CreditScore BETWEEN 600 AND 699 THEN 'Medium'
        ELSE 'High'
    END AS CreditSegment,
    COUNT(*) AS TotalCustomers,
    SUM(Exited) AS ExitedCustomers,
    ROUND(AVG(Exited) * 100, 2) AS ExitRatePercentage
FROM bank_churn
GROUP BY
    CASE
        WHEN CreditScore < 600 THEN 'Low'
        WHEN CreditScore BETWEEN 600 AND 699 THEN 'Medium'
        ELSE 'High'
    END
ORDER BY ExitRatePercentage DESC;

/* 8) Find out which geographic region has the highest number of active customers with a tenure greater than 5 years. */

SELECT 
    ci.GeographyID AS Region,
    COUNT(*) AS ActiveCustomersWithHighTenure
FROM bank_churn bc
JOIN customerinfo ci ON bc.CustomerId = ci.CustomerId
WHERE bc.Exited = 0
  AND bc.Tenure > 5
GROUP BY ci.GeographyID
ORDER BY ActiveCustomersWithHighTenure DESC
LIMIT 1;

/* 9) What is the impact of having a credit card on customer churn, based on the available data? */

SELECT
    HasCrCard,
    COUNT(*) AS TotalCustomers,
    SUM(Exited) AS ExitedCustomers,
    ROUND(AVG(Exited) * 100, 2) AS CustomerChurnPercentage
FROM bank_churn
GROUP BY HasCrCard;

/* 10.	For customers who have exited, what is the most common number of products they have used? */

SELECT 
    NumOfProducts,
    COUNT(*) AS ExitedCustomerCount
FROM bank_churn
WHERE Exited = 1
GROUP BY NumOfProducts
ORDER BY ExitedCustomerCount DESC
LIMIT 1;

/* 11.	Examine the trend of customers joining over time and
 identify any seasonal patterns (yearly or monthly). Prepare the data through SQL and then visualize it. */
 
 SELECT
    YEAR(Bank_DOJ) AS JoinYear,
    MONTH(Bank_DOJ) AS JoinMonth,
    COUNT(*) AS CustomersJoined
FROM customerinfo
GROUP BY YEAR(Bank_DOJ), MONTH(Bank_DOJ)
ORDER BY JoinYear, JoinMonth;

/* 12.	Analyze the relationship between the number of products and the account balance for customers who have exited. */
SELECT
    NumOfProducts,
    COUNT(*) AS ExitedCustomers,
    ROUND(AVG(Balance), 2) AS AvgBalance
FROM bank_churn
WHERE Exited = 1
GROUP BY NumOfProducts
ORDER BY NumOfProducts;

/* 13.	Identify any potential outliers in terms of balance among customers who have remained with the bank.*/


/* Step 1: Get total count of active customers*/

SELECT COUNT(*) AS TotalActive FROM bank_churn WHERE Exited = 0;

-- Step 2: Get Q1(25th Percentile)
SELECT Balance AS Q1
FROM bank_churn
WHERE Exited = 0
ORDER BY Balance
LIMIT 1 OFFSET 1989;

-- Step 3: Get Q3(75th Percentile)
SELECT Balance AS Q3
FROM bank_churn
WHERE Exited = 0
ORDER BY Balance
LIMIT 1 OFFSET 5971;

-- Step 4: To find Outliers
SELECT *
FROM bank_churn
WHERE Exited = 0
  AND Balance > 315980.45;

/* 15.	Using SQL, write a query to find out the gender-wise average income of males and females in each geography id. Also,
 rank the gender according to the average value. */
 
 SELECT
    GeographyID,
    GenderID,
    AVG(EstimatedSalary) AS Avg_Income,
    RANK() OVER (PARTITION BY GeographyID ORDER BY AVG(EstimatedSalary) DESC) AS Income_Rank
FROM
    customerinfo
GROUP BY
    GeographyID,
    GenderID;
    
/* 16.	Using SQL, write a query to find out the average tenure of the people who have exited in each age bracket (18-30, 30-50, 50+).*/

SELECT
    CASE
        WHEN Age BETWEEN 18 AND 30 THEN '18-30'
        WHEN Age BETWEEN 31 AND 50 THEN '31-50'
        ELSE '51+'
    END AS Age_Bracket,
    AVG(Tenure) AS Avg_Tenure
FROM
    bank_churn bc
JOIN
    customerinfo ci ON bc.CustomerId = ci.CustomerId
WHERE
    Exited = 1
GROUP BY
    CASE
        WHEN Age BETWEEN 18 AND 30 THEN '18-30'
        WHEN Age BETWEEN 31 AND 50 THEN '31-50'
        ELSE '51+'
    END;
    
/*19.	Rank each bucket of credit score as per the number of customers who have churned the bank.*/

SELECT 
    CreditScoreBucket,
    ChurnedCustomers,
    RANK() OVER (ORDER BY ChurnedCustomers DESC) AS Rnk
FROM (
    SELECT 
        CASE
            WHEN CreditScore BETWEEN 300 AND 499 THEN '300-499'
            WHEN CreditScore BETWEEN 500 AND 599 THEN '500-599'
            WHEN CreditScore BETWEEN 600 AND 699 THEN '600-699'
            WHEN CreditScore BETWEEN 700 AND 799 THEN '700-799'
            WHEN CreditScore BETWEEN 800 AND 900 THEN '800-900'
            ELSE 'Other'
        END AS CreditScoreBucket,
        COUNT(*) AS ChurnedCustomers
    FROM bank_churn
    WHERE Exited = 1
    GROUP BY CreditScoreBucket
) AS BucketCounts
ORDER BY Rnk;

/* 20.	According to the age buckets find the number of customers who have a credit card. 
Also retrieve those buckets that have lesser than average number of credit cards per bucket.*/

WITH AgeBuckets AS (
    SELECT 
        CASE
            WHEN ci.Age BETWEEN 18 AND 25 THEN '18-25'
            WHEN ci.Age BETWEEN 26 AND 35 THEN '26-35'
            WHEN ci.Age BETWEEN 36 AND 45 THEN '36-45'
            WHEN ci.Age BETWEEN 46 AND 55 THEN '46-55'
            WHEN ci.Age BETWEEN 56 AND 65 THEN '56-65'
            WHEN ci.Age > 65 THEN '65+'
            ELSE 'Unknown'
        END AS AgeBucket,
        bc.HasCrCard
    FROM customerinfo ci
    JOIN bank_churn bc ON ci.CustomerId = bc.CustomerId
),
CreditCardCounts AS (
    SELECT 
        AgeBucket,
        COUNT(*) AS TotalCustomers,
        SUM(CASE WHEN HasCrCard = 1 THEN 1 ELSE 0 END) AS CreditCardHolders
    FROM AgeBuckets
    GROUP BY AgeBucket
),
AverageCardHolders AS (
    SELECT AVG(CreditCardHolders) AS AvgCardHoldersPerBucket
    FROM CreditCardCounts
)
SELECT 
    c.AgeBucket,
    c.CreditCardHolders
FROM CreditCardCounts c
JOIN AverageCardHolders a
    ON c.CreditCardHolders < a.AvgCardHoldersPerBucket;

/* 21.	Rank the Locations as per the number of people who have churned the bank and average balance of the customers.*/

SELECT 
    Location,
    Num_Churned_Customers,
    Avg_Balance,
    RANK() OVER (ORDER BY Num_Churned_Customers DESC, Avg_Balance DESC) AS Location_Rank
FROM (
    SELECT 
        ci.GeographyID AS Location,
        COUNT(CASE WHEN bc.Exited = 1 THEN 1 END) AS Num_Churned_Customers,
        AVG(bc.Balance) AS Avg_Balance
    FROM 
        customerinfo ci
    JOIN 
        bank_churn bc ON ci.CustomerId = bc.CustomerId
    GROUP BY 
        ci.GeographyID
) AS RankedLocations;

/* 23.	Without using “Join”, can we get the “ExitCategory” from ExitCustomers table to Bank_Churn table? If yes do this using SQL.*/

SELECT 
    CustomerId,
    CreditScore,
    Tenure,
    Balance,
    NumOfProducts,
    HasCrCard,
    IsActiveMember,
    Exited,
    CASE 
        WHEN Exited = 1 THEN 'Exit'
        WHEN Exited = 0 THEN 'Retain'
        ELSE 'Unknown'
    END AS ExitCategory
FROM 
    Bank_Churn;
    
/* 25.	Write the query to get the customer IDs, their last name, 
and whether they are active or not for the customers whose surname ends with “on”. */

SELECT ci.CustomerId, 
       ci.Surname, 
       bc.Exited
FROM customerinfo ci
JOIN bank_churn bc ON ci.CustomerId = bc.CustomerId
WHERE ci.Surname LIKE '%on';

/* Subjective : 1.	Customer Behavior Analysis: What patterns can be observed in the spending habits of long-term customers compared to
new customers, and what might these patterns suggest about customer loyalty? */

SELECT 
    CASE
        WHEN b.Tenure >= 5 THEN 'Long-Term'
        WHEN b.Tenure <= 2 THEN 'New'
        ELSE 'Mid-Term'
    END AS Customer_Type,
    COUNT(*) AS Total_customers,
    ROUND(AVG(b.Balance), 2) AS AvgBalance,
    ROUND(AVG(c.EstimatedSalary), 2) AS AvgSalary,
    ROUND(AVG(b.Exited) * 100, 2) AS ChurnRate_Percent,
    ROUND(AVG(b.IsActiveMember) * 100, 2) AS ActiveRate_Percent
FROM
    CustomerInfo c
        JOIN
    Bank_Churn b ON c.CustomerId = b.CustomerId
GROUP BY CASE
    WHEN b.Tenure >= 5 THEN 'Long-Term'
    WHEN b.Tenure <= 2 THEN 'New'
    ELSE 'Mid-Term'
END;

/* 2.	Product Affinity Study: Which bank products or services are most commonly used together, and how might this influence 
cross-selling strategies? */

SELECT 
    -- Product affinity combinations
    SUM(CASE WHEN bc.HasCrCard = 1 AND bc.Balance > 0 THEN 1 ELSE 0 END) AS CrCard_And_Savings,
    SUM(CASE WHEN bc.HasCrCard = 1 AND bc.NumOfProducts >= 2 THEN 1 ELSE 0 END) AS CrCard_And_MultiProduct,
    SUM(CASE WHEN bc.Balance > 0 AND bc.NumOfProducts >= 2 THEN 1 ELSE 0 END) AS Savings_And_MultiProduct,
    SUM(CASE WHEN bc.HasCrCard = 1 AND bc.Exited = 1 THEN 1 ELSE 0 END) AS CrCard_And_Active,
    SUM(CASE WHEN bc.NumOfProducts = 1 AND ci.EstimatedSalary > 100000 THEN 1 ELSE 0 END) AS HighSalary_SingleProduct,
    COUNT(*) AS TotalCustomers
FROM bank_churn bc
JOIN customerinfo ci 
    ON bc.CustomerId = ci.CustomerId;
    
/* 3.	Geographic Market Trends: How do economic indicators in different geographic regions correlate with 
the number of active accounts and customer churn rates? */ 

SELECT 
    c.GeographyID AS Region,
    COUNT(c.CustomerId) AS Total_Customers,
    AVG(c.EstimatedSalary) AS Avg_Estimated_Salary,
    SUM(CASE WHEN b.Exited = 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS Active_Percentage,
    SUM(CASE WHEN b.Exited = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS Churn_Percentage
FROM 
    customerinfo c
JOIN 
    bank_churn b ON c.CustomerId = b.CustomerId
GROUP BY 
    c.GeographyID;
    
/* 4.	Risk Management Assessment: Based on customer profiles, which demographic segments appear
 to pose the highest financial risk to the bank, and why? */
 
 SELECT 
    c.GeographyID AS Region,
    FLOOR(c.Age / 10) * 10 AS Age_Group,
    COUNT(c.CustomerId) AS Total_Customers,
    round(AVG(b.CreditScore),2) AS Avg_CreditScore,
    round(AVG(b.Balance),2) AS Avg_Balance,
    round(SUM(CASE WHEN b.Exited = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*),2) AS Churn_Percentage
FROM 
    customerinfo c
JOIN 
    bank_churn b ON c.CustomerId = b.CustomerId
GROUP BY 
	c.GeographyID, FLOOR(c.Age / 10) * 10
ORDER BY 
    Churn_Percentage DESC;


/* 7.	Customer Exit Reasons Exploration: Can you identify common characteristics or trends
 among customers who have exited that could explain their reasons for leaving? */
 
 SELECT 
    NumOfProducts,
    COUNT(*) AS Total_Customers,
    SUM(CASE WHEN Exited = 1 THEN 1 ELSE 0 END) AS Exited_Customers,
    ROUND(
        SUM(CASE WHEN Exited = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ) AS Churn_Rate_Percent
FROM 
    bank_churn
GROUP BY 
    NumOfProducts
ORDER BY 
    Churn_Rate_Percent DESC;
    
/* SQL query for tenure: */
SELECT 
    Tenure,
    COUNT(*) AS Total_Customers,
    SUM(CASE WHEN Exited = 1 THEN 1 ELSE 0 END) AS Exited_Customers,
    ROUND(
        SUM(CASE WHEN Exited = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ) AS Churn_Rate_Percent
FROM 
    bank_churn
GROUP BY 
    Tenure
ORDER BY 
    Churn_Rate_Percent DESC;

/*SQL query for Location: */

SELECT 
    c.GeographyID,
    COUNT(*) AS Total_Customers,
    SUM(CASE
        WHEN bc.Exited = 1 THEN 1
        ELSE 0
    END) AS Exited_Customers,
    ROUND(SUM(CASE
                WHEN bc.Exited = 1 THEN 1
                ELSE 0
            END) * 100.0 / COUNT(*),
            2) AS Churn_Rate_Percent
FROM
    bank_churn bc
        JOIN
    customerinfo c ON bc.customerID = c.customerID
GROUP BY c.GeographyID
ORDER BY Churn_Rate_Percent DESC;

/*SQL query for Estimated salary:*/
SELECT 
    CASE 
        WHEN ci.EstimatedSalary < 50000 THEN 'Under 50K'
        WHEN ci.EstimatedSalary BETWEEN 50000 AND 100000 THEN '50K - 100K'
        WHEN ci.EstimatedSalary BETWEEN 100001 AND 150000 THEN '100K - 150K'
        ELSE '150K+' 
    END AS SalaryRange,
    COUNT(bc.CustomerId) AS TotalCustomers,
    SUM(bc.Exited) AS ExitedCustomers,
    ROUND(SUM(bc.Exited) * 100.0 / COUNT(bc.CustomerId), 2) AS ChurnRate
FROM 
    bank_churn bc
JOIN 
    customerinfo ci ON bc.CustomerId = ci.CustomerId
GROUP BY 
    SalaryRange
ORDER BY 
    ChurnRate DESC;



/* 9.	Utilize SQL queries to segment customers based on demographics and account details. */    
/*SQL query for Segment by Age Group */

SELECT 
    CASE 
        WHEN Age BETWEEN 18 AND 25 THEN '18-25'
        WHEN Age BETWEEN 26 AND 35 THEN '26-35'
        WHEN Age BETWEEN 36 AND 45 THEN '36-45'
        WHEN Age BETWEEN 46 AND 55 THEN '46-55'
        WHEN Age BETWEEN 56 AND 65 THEN '56-65'
        ELSE '65+'
    END AS Age_Group,
    COUNT(*) AS Customer_Count
FROM customerinfo
GROUP BY 
    CASE 
        WHEN Age BETWEEN 18 AND 25 THEN '18-25'
        WHEN Age BETWEEN 26 AND 35 THEN '26-35'
        WHEN Age BETWEEN 36 AND 45 THEN '36-45'
        WHEN Age BETWEEN 46 AND 55 THEN '46-55'
        WHEN Age BETWEEN 56 AND 65 THEN '56-65'
        ELSE '65+'
    END
ORDER BY Customer_Count DESC;

/*SQL query to Segment by Gender and Churn Status*/
SELECT 
    ci.GenderID,
    bc.Exited,
    COUNT(*) AS Customer_Count
FROM customerinfo ci
JOIN bank_churn bc ON ci.CustomerId = bc.CustomerId
GROUP BY GenderID, bc.Exited;

/* SQL query to Segment by Geography and Account Activity */ 

SELECT ci.GeographyID,
    bc.Exited,
    COUNT(*) AS Customer_Count
FROM customerinfo ci
JOIN bank_churn bc ON ci.CustomerId = bc.CustomerId
GROUP BY ci.GeographyID, bc.Exited;

/* SQL query to Segment by Credit Score Range */
SELECT 
    CASE 
        WHEN CreditScore < 600 THEN 'Low'
        WHEN CreditScore BETWEEN 600 AND 750 THEN 'Medium'
        ELSE 'High'
    END AS CreditScore_Segment,
    COUNT(*) AS Customer_Count
FROM bank_churn
GROUP BY CreditScore_Segment;







 
 














