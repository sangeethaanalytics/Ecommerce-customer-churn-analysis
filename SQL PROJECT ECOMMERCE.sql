USE ecomm;

select * from customer_churn;


-- Data cleaning.
-- Handling missing values and outliers.

SET SQL_SAFE_UPDATES = 0;
SELECT 
    ROUND(AVG(WarehouseToHome)) AS Avg_WarehouseToHome,
    ROUND(AVG(HourSpendOnApp)) AS Avg_HourSpendOnApp,
    ROUND(AVG(OrderAmountHikeFromlastYear)) AS Avg_OrderAmountHikeFromlastYear,
    ROUND(AVG(DaySinceLastOrder)) AS Avg_DaySinceLastOrder
FROM Customer_churn;

UPDATE customer_churn
set 
 warehouseToHome =@Avg_WarehouseToHome,
 HourSpendOnApp =@Avg_HourSpendOnApp,
 OrderAmountHikeFromlastYear =@Avg_OrderAmountHikeFromlastYear,
 DaySinceLastOrder =@Avg_DaySinceLastOrder;
 
 -- II impute for the columns
 SELECT Tenure 
FROM customer_churn 
GROUP BY Tenure 
ORDER BY COUNT(*) DESC 
LIMIT 1;

SELECT CouponUsed 
FROM customer_churn 
GROUP BY CouponUsed 
ORDER BY COUNT(*) DESC 
LIMIT 1;

SELECT OrderCount 
FROM customer_churn 
GROUP BY OrderCount 
ORDER BY COUNT(*) DESC 
LIMIT 1;

UPDATE customer_churn
SET Tenure = 1
WHERE Tenure IS NULL;

UPDATE customer_churn
SET CouponUsed = 1
WHERE CouponUsed IS NULL;

UPDATE customer_churn
SET OrderCount = 2
WHERE OrderCount IS NULL;


	DELETE FROM customer_churn
WHERE WarehouseToHome > 100;

-- Dealing with Inconsistencies:

 -- Replace occurrences of “Phone” in the 'PreferredLoginDevice' column
update customer_churn
set 
PreferredLoginDevice = if(preferredlogindevice= 'phone','mobile phone',preferredlogindevice),
PreferedOrderCat = if(PreferedOrderCat = 'mobile','mobile phone',PreferedOrderCat);

-- Standardize payment mode values
Update customer_churn
set PreferredPaymentMode = case
					when PreferredPaymentMode = 'COD' THEN 'Cash on Delivery'
                    when PreferredPaymentMode = 'CC' THEN 'Credit Card'
                    else PreferredPaymentMode
                    end;
                    
  --  Data Transformation
  -- Column Renaming
  alter table customer_churn
  RENAME COLUMN PreferedOrderCat TO PreferredOrderCat,
  RENAME COLUMN HourSpendOnApp TO HoursSpentOnApp;
  
  -- CREATING NEW COLUMNS
 ALTER TABLE customer_churn
DROP COLUMN ComplaintReceived;

ALTER TABLE customer_churn
ADD COLUMN ComplaintReceived ENUM('YES','NO');
  
UPDATE customer_churn
SET ComplaintReceived = IF(Complain = 1, 'YES', 'NO');

-- ALTER TABLE customer_churn
ALTER TABLE customer_churn
ADD COLUMN ChurnStatus ENUM('Churned', 'Active');

UPDATE customer_churn
SET ChurnStatus = IF(Churn = 1, 'Churned', 'Active');

-- Colum Dropping
ALTER TABLE customer_churn
DROP COLUMN churn,
DROP COLUMN complain;

--- Data Exploration and analysis
SELECT 
    ChurnStatus, 
    COUNT(*) AS CustomerCount
FROM customer_churn
GROUP BY ChurnStatus;
-- Display the average tenure and total cashback amount of customers who churned
SELECT 
    FLOOR(AVG(Tenure)) AS Avg_Tenure,
    SUM(CashbackAmount) AS Total_Cashback
FROM customer_churn
WHERE ChurnStatus = 'Churned';

--- Determine the percentage of churned customers who complained.
SELECT 
    CONCAT(
        ROUND(
            (COUNT(*) / (SELECT COUNT(*) FROM customer_churn WHERE ChurnStatus = 'Churned')) * 100,
            2
        ), '%'
    ) AS Churn_Complaint_Percentage
FROM customer_churn
WHERE ChurnStatus = 'Churned' AND ComplaintReceived = 'Yes';

--- Find the gender distribution of customers who complained.
SELECT 
    Gender,
    COUNT(*) AS Complaint_Count
FROM customer_churn
WHERE ComplaintReceived = 'Yes'
GROUP BY Gender;
--- Identify the city tier with the highest number of churned customers whose preferred order category is Laptop & Accessory.
SELECT 
    CityTier,
    COUNT(*) AS Churned_Customers
FROM customer_churn
WHERE 
    ChurnStatus = 'Churned'
    AND PreferredOrderCat = 'Laptop & Accessory'
GROUP BY CityTier
ORDER BY Churned_Customers DESC
LIMIT 1;

--- Identify the most preferred payment mode among active customers.
SELECT 
    PreferredPaymentMode,
    COUNT(*) AS Active_Customers
FROM customer_churn
WHERE ChurnStatus = 'Active'
GROUP BY PreferredPaymentMode
ORDER BY Active_Customers DESC
LIMIT 1;

-- Calculate the total order amount hike from last year for customers who are single and prefer mobile phones for ordering.
SELECT 
    SUM(OrderAmountHikeFromlastYear) AS Total_Hike
FROM customer_churn
WHERE 
    MaritalStatus = 'Single'
    AND PreferredOrderCat = 'Mobile Phone';
    
--- Find the average number of devices registered among customers who used UPI as their preferred payment mode.
SELECT 
    ROUND(AVG(NumberOfDeviceRegistered), 2) AS Avg_Devices_Registered
FROM customer_churn
WHERE PreferredPaymentMode = 'UPI';

--- Determine the city tier with the highest number of customers
SELECT 
    CityTier,
    COUNT(*) AS Total_Customers
FROM customer_churn
GROUP BY CityTier
ORDER BY Total_Customers DESC
LIMIT 1;

--- Identify the gender that utilized the highest number of coupons
SELECT 
    Gender,
    SUM(CouponUsed) AS Total_Coupons_Used
FROM customer_churn
GROUP BY Gender
ORDER BY Total_Coupons_Used DESC
LIMIT 1;

--- List the number of customers and the maximum hours spent on the app in each preferred order category.
SELECT 
    PreferredOrderCat,
    COUNT(*) AS Total_Customers,
    MAX(HoursSpentOnApp) AS Max_Hours_Spent
FROM customer_churn
GROUP BY PreferredOrderCat;

--- Calculate the total order count for customers who prefer using credit cards and have the maximum satisfaction score
SELECT MAX(SatisfactionScore) FROM customer_churn;
SELECT 
    SUM(OrderCount) AS Total_Orders
FROM customer_churn
WHERE 
    PreferredPaymentMode = 'Credit Card'
    AND SatisfactionScore = (SELECT MAX(SatisfactionScore) FROM customer_churn);
    
--- How many customers are there who spent only one hour on the app and days since their last order was more than 5?
SELECT 
    COUNT(*) AS Customer_Count
FROM 
    customer_churn
WHERE 
    HoursSpentOnApp = 1
    AND DaySinceLastOrder > 5;
--- What is the average satisfaction score of customers who have complained?
SELECT 
    ROUND(AVG(SatisfactionScore), 2) AS Avg_Satisfaction_Score
FROM 
    customer_churn
WHERE 
    ComplaintReceived = 'Yes';
--- List the preferred order category among customers who used more than 5 coupons
SELECT 
    PreferredOrderCat,
    COUNT(*) AS Customer_Count
FROM 
    customer_churn
WHERE 
    CouponUsed > 5
GROUP BY 
    PreferredOrderCat
ORDER BY 
    Customer_Count DESC;
    
--- List the top 3 preferred order categories with the highest average cashback amount.
SELECT 
    PreferredOrderCat,
    ROUND(AVG(CashbackAmount), 2) AS Avg_Cashback
FROM 
    customer_churn
GROUP BY 
    PreferredOrderCat
ORDER BY 
    Avg_Cashback DESC
LIMIT 3;

--- Find the preferred payment modes of customers whose average tenure is 10 months and have placed more than 500 orders.
SELECT 
    PreferredPaymentMode,
    COUNT(*) AS Customer_Count
FROM 
    customer_churn
WHERE 
    Tenure = 10
    AND OrderCount > 500
GROUP BY 
    PreferredPaymentMode
ORDER BY 
    Customer_Count DESC;
    
--- Categorize customers based on their distance from the warehouse to home such as 'Very Close Distance' for distances <=5km, 'Close Distance' for <=10km, 'Moderate Distance' for <=15km, and 'Far Distance' for >15km. Then, display the churn status breakdown for each distance category.
	SELECT
    CASE
        WHEN WarehouseToHome <= 5 THEN 'Very Close Distance'
        WHEN WarehouseToHome <= 10 THEN 'Close Distance'
        WHEN WarehouseToHome <= 15 THEN 'Moderate Distance'
        ELSE 'Far Distance'
    END AS Distance_Category,
    ChurnStatus,
    COUNT(*) AS Customer_Count
FROM 
    customer_churn
GROUP BY 
    Distance_Category, ChurnStatus
ORDER BY 
    FIELD(Distance_Category, 'Very Close Distance', 'Close Distance', 'Moderate Distance', 'Far Distance'),
    ChurnStatus;
    
  SELECT 
    CustomerID,
    MaritalStatus,
    CityTier,
    OrderCount
FROM 
    customer_churn
WHERE 
    MaritalStatus = 'Married'
    AND CityTier = 1
    AND OrderCount > (
        SELECT AVG(OrderCount)
        FROM customer_churn
    );
    
    CREATE TABLE customer_returns (
    ReturnID INT PRIMARY KEY,
    CustomerID INT,
    ReturnDate DATE,
    RefundAmount DECIMAL(10,2)
);

INSERT INTO customer_returns (ReturnID, CustomerID, ReturnDate, RefundAmount)
VALUES
(1001, 50022, '2023-01-01', 2130),
(1002, 50316, '2023-01-23', 2000),
(1003, 51099, '2023-02-14', 2290),
(1004, 52321, '2023-03-08', 2510),
(1005, 52928, '2023-03-20', 3000),
(1006, 53749, '2023-04-17', 1740),
(1007, 54206, '2023-04-21', 3250),
(1008, 54838, '2023-04-30', 1990);
SELECT * FROM customer_returns;

SELECT 
    c.CustomerID,
    c.MaritalStatus,
    c.CityTier,
    c.Complain,
    c.Churn,
    r.ReturnID,
    r.ReturnDate,
    r.RefundAmount
FROM 
    customer_churn c
JOIN 
    customer_returns r 
ON 
    c.CustomerID = r.CustomerID
WHERE 
    c.Churn = 1
    AND c.Complain = 1;