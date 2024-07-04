--Telecom Growth Strategies Unlocking Customer Lifetime Value Through Smart Segmentation 

--create table in schema--
CREATE TABLE "Nexa_Sat".nexa_sat(
		Customer_ID varchar(50),
		gender varchar(10),
		Partner varchar(5),
		Dependents varchar(3),
		Senior_Citizen int,
		Call_Duration float,
		Data_Usage float,
		Plan_Type varchar(20),
		Plan_Level varchar(20),
		Monthly_Bill_Amount float,
		Tenure_Months int,
		Multiple_Lines varchar(3),
		Tech_Support varchar(3),
		Churn int
);


SELECT * FROM "Nexa_Sat".nexa_sat;




--Confirm current Schema--
SELECT current_schema();

--Set path for queries
SET search_path TO "Nexa_Sat";


--Confirm current Schema--
SELECT current_schema();

--View Data
SELECT * FROM
"nexa_sat";


--DATA CLEANING

SELECT Customer_ID,	gender,	Partner,	Dependents,
	Senior_Citizen,	Call_Duration,	Data_Usage,
	Plan_Type,	Plan_Level,	Monthly_Bill_Amount,
	Tenure_Months,	Multiple_Lines,	Tech_Support,
	Churn
FROM nexa_sat
GROUP BY Customer_ID,	gender,	Partner,	Dependents,
	Senior_Citizen,	Call_Duration,	Data_Usage,
	Plan_Type,	Plan_Level,	Monthly_Bill_Amount,
	Tenure_Months,	Multiple_Lines,	Tech_Support,
	Churn
HAVING COUNT(*)> 1; --This filter duplicate rows

--NB: NO Duplicate Rows in the data


-- Check for null values
SELECT *
FROM nexa_sat
WHERE Customer_ID IS NULL
OR gender IS NULL
OR Partner IS NULL
OR Dependents IS NULL
OR Senior_Citizen IS NULL
OR Call_Duration IS NULL
OR Data_Usage IS NULL
OR Plan_Type IS NULL
OR Plan_Level IS NULL
OR Monthly_Bill_Amount IS NULL
OR Tenure_Months IS NULL
OR Multiple_Lines IS NULL
OR Tech_Support IS NULL
OR Churn IS NULL;

--NB; No Null Values in dataset


/*EXPLORATORY DATA ANALYSIS (EDA)
Basic EDA:
-Total Users;
-Total Count of Users by Plan Level;
-Total Revenue;
-Revenue By Plan Level;
-Churn Count by Plan Type and Plan Level;
-Avg Tenure By Plan Level;
*/

--Total Users; = 4272
SELECT COUNT(Customer_ID) AS current_users
FROM nexa_sat
WHERE churn = 0;

--Total Count of Users by Plan Level; Premium = 3015, Basic = 1257
SELECT plan_level, COUNT(Customer_ID) AS total_users
FROM nexa_sat
WHERE churn = 0
GROUP BY 1;

--Total Revenue = 1054953.70
SELECT ROUND(SUM(Monthly_bill_amount::numeric),2) AS revenue
FROM nexa_sat;


-- Revenue By Plan Level;=
-- Basic: 426622.00
-- Premium: 628331.70
SELECT plan_level, ROUND(SUM(Monthly_bill_amount::numeric),2) AS revenue_plan
FROM nexa_sat
GROUP BY 1
ORDER BY 2;

--Churn Count by Plan Type and Plan Level;
/*"plan_level"	"plan_type"	"total_customers"	"chur_count"
"Basic"			"Prepaid"		1108				623
"Basic"			"Postpaid"		2355				1583
"Premium"		"Prepaid"		1832				220
"Premium"		"Postpaid"		1748				345
*/
SELECT plan_level,
		plan_type,
		COUNT(*) AS total_customers,
		SUM(churn) AS churn_count
FROM nexa_sat
GROUP BY 1, 2
ORDER BY 1;

-- Avg Tenure By Plan Level;
-- "Premium"	32.16
-- "Basic"	    16.61
SELECT plan_level, ROUND(AVG(Tenure_Months), 2) AS avg_tenure
FROM nexa_sat
GROUP BY 1;

/*CLV SEGMENTATION
    MARKETING SEGMENTS
-Project is a CLV segmentation, here market will be segmented
-To Analyze the segments
-Come up with a marketting strategy for the segments
*/

-- Create Table of Existing Users Only
CREATE TABLE existing_users AS
SELECT *
FROM nexa_sat
WHERE churn = 0;

-- View New Table
SELECT *
FROM existing_users;

--Calculate Avg Rev Per User(ARPU) for existing = 157.54
SELECT ROUND(AVG(Monthly_Bill_Amount::INT), 2) AS ARPU_Total
FROM existing_users;

--Calculate the CLV and Column
ALTER TABLE existing_users
ADD COLUMN clv FLOAT;

UPDATE existing_users
SET clv = 	Monthly_Bill_Amount * Tenure_Months;


-- View New CLV Column
SELECT Customer_ID, clv
FROM existing_users;

-- CLV Score; Determine How to weight different Variables by assigning the following weights
-- Monthly_Bill_Amount = 40%
-- Tenure = 30%
-- Call_Duration = 10%
-- Data_Usage = 10%
-- Plan_Level('Premium')= 10%

ALTER TABLE existing_users
ADD COLUMN clv_score NUMERIC(10,2);


UPDATE existing_users
SET clv_score = 
			(0.4 * Monthly_Bill_Amount) +
			(0.3 * Tenure_Months) +
			(0.1 * Call_Duration)+
			(0.1 * Data_Usage)+
			(0.1 * CASE WHEN Plan_Level = 'Premium'
					THEN 1 ELSE 0
					END);
SELECT Customer_ID, clv_score
FROM existing_users;

-- Group Users Into Segments Based on clv_score
ALTER TABLE existing_users
ADD COLUMN clv_segments VARCHAR;

UPDATE existing_users
SET clv_segments = 
			CASE WHEN clv_score > (SELECT percentile_cont(0.85)
								  WITHIN GROUP (ORDER BY clv_score)
								  FROM existing_users) THEN 'High Value'
				WHEN clv_score >= (SELECT percentile_cont(0.50)
								   WITHIN GROUP (ORDER BY clv_score)
								  FROM existing_users) THEN 'Moderate Value'
				WHEN clv_score >= (SELECT percentile_cont(0.25)
								   WITHIN GROUP (ORDER BY clv_score)
								  FROM existing_users) THEN 'Low Value'
				ELSE 'Churn Risk'
				END;

-- View Segments
SELECT Customer_ID, clv_score, clv_segments
FROM existing_users;



/*ANALYZIG CREATED SEGMENTS
-AVG Bill and Tenure per Segments
-No. of people having tech support and multiple lines
-Revenue per segment
*/



-- AVG Bill and Tenure per Segments
SELECT  clv_segments,
		ROUND(AVG(Monthly_Bill_Amount::INT), 2) AS avg_monthly_charges,
		ROUND(AVG(Tenure_Months::INT), 2) AS avg_tenure_cost
FROM  existing_users
GROUP BY 1;
		


-- No. of people having tech support and multiple lines
SELECT clv_segments,
		ROUND(AVG(CASE WHEN Tech_Support = 'Yes' THEN 1 ELSE 0 END), 2) AS tech_support_pct,
		ROUND(AVG(CASE WHEN Multiple_Lines = 'Yes' THEN 1 ELSE 0 END), 2) AS multiple_line_pct
FROM existing_users
GROUP BY 1;

-- Revenue per segment
SELECT  clv_segments, COUNT(Customer_ID),
		CAST(SUM(Monthly_Bill_Amount * Tenure_Months) AS NUMERIC(10,2)) AS total_revenue
FROM existing_users
GROUP BY 1;

/* Upselling And Cross Selling(Additional Service) Strategies:
- Strategies for various segments from
- Usage pattern and Demographic Data For Upselling and Cross Selling
- Offer Tech supports, services, all customers
*/

-- Cross Selling(Additional Service) TO Senior_Citizens
SELECT Customer_ID
FROM existing_users
WHERE Senior_Citizen = 1 --Senior_Citizens
AND Dependents = 'No' --No children or tech helpers
AND Tech_Support= 'No' --No Service
AND (clv_segments = 'Churn Risk' OR clv_segments = 'Low value');



-- Cross Selling(Additional Service) Multiple_Lines for Partner and Dependents 
SELECT Customer_ID
FROM existing_users
WHERE Multiple_Lines = 'No'
AND (Dependents = 'Yes' OR Partner = 'Yes')
AND Plan_Level = 'Basic';

--Upselling: Premium Discount for Basic users churn risk
SELECT Customer_ID
FROM existing_users
WHERE clv_segments = 'Churn Risk'
AND Plan_Level = 'Basic';

--Upselling: Basic to Premium for longer lock period to premium and hiher ARPU
SELECT Plan_Level, ROUND(AVG(Monthly_Bill_Amount::INT),2) AS avg_bill, ROUND(AVG(Tenure_Months::INT), 2) AS avg_tenure
FROM existing_users
WHERE clv_segments = 'High Value'
OR clv_segments = 'Moderate Value'
GROUP BY 1;

--SELECT Customers -- High Usage to Premium Upgrade
SELECT Customer_ID, Monthly_Bill_Amount
FROM  existing_users
WHERE Plan_Level ='Basic'
AND (clv_segments = 'High Value' OR clv_segments = 'Moderate Value')
AND Monthly_Bill_Amount > 150;


--CREATE STORED PROCEDURES
--snr citizens to be offered support
CREATE FUNCTION Tech_Support_Senior_Citizen()
RETURNS TABLE (Customer_ID VARCHAR(50))
AS $$
BEGIN
	RETURN QUERY
	SELECT Customer_ID
	FROM existing_users eu
	WHERE eu.Senior_Citizen = 1 --Senior_Citizens
	AND eu.Dependents = 'No' --No children or tech helpers
	AND eu.Tech_Support= 'No' --No Service
	AND (eu.clv_segments = 'Churn Risk' OR eu.clv_segments = 'Low value');
END;
$$ LANGUAGE plpgsql


--To be offered Discount
CREATE FUNCTION churn_risk_discount()
RETURNS TABLE(Customer_ID VARCHAR(50))
AS $$
BEGIN
	RETURN QUERY
	SELECT Customer_ID
	FROM existing_users eu
	WHERE eu.clv_segments = 'Churn Risk'
	AND eu.Plan_Level = 'Basic';
END;
$$ LANGUAGE plpgsql


-- High Usage Customers to be offered premium upgrade
CREATE FUNCTION high_usage_basic()
RETURNS TABLE(Customer_ID VARCHAR(50))
AS $$
BEGIN
	RETURN QUERY
	SELECT Customer_ID
	FROM  existing_users eu
	WHERE eu.Plan_Level ='Basic'
	AND (eu.clv_segments = 'High Value' OR eu.clv_segments = 'Moderate Value')
	AND eu.Monthly_Bill_Amount > 150;
END;
$$ LANGUAGE plpgsql

--USE PROCEDURES
SELECT * 
FROM churn_risk_discount();

--High Usage Basic Customers
SELECT *
FROM high_usage_basic();








Customer_ID, clv_score, clv_segments existing_users;

Customer_ID,	gender,	Partner,	Dependents,
	Senior_Citizen,	Call_Duration,	Data_Usage,
	Plan_Type,	Plan_Level,	Monthly_Bill_Amount,
	Tenure_Months,	Multiple_Lines,	Tech_Support,
	Churn



