CREATE DATABASE MPsExpenditure_22_23
USE MPsExpenditure_22_23

-- Add Foreign KEY to MPsExpenditure table

ALTER TABLE MPsExpenditure
ADD FOREIGN KEY (MPID) REFERENCES MPs(MPID)

ALTER TABLE MPsExpenditure
ADD FOREIGN KEY (ConstituencyID) REFERENCES Regions(ConstituencyID)

-- Tables of the database:

--1. Fact table with data about budgets and spending
SELECT *
FROM MPsExpenditure
--2. Dimension table with data about the Members of Parliament
SELECT *
FROM MPs
--3. Dimension table with data about their Constituency
SELECT *
FROM Regions

-- Quantity of Members of Parliament by country

SELECT 
	COUNT(MPID) AS [Quantity],
	Country
FROM Regions AS r
	INNER JOIN MPsExpenditure AS mpe ON r.ConstituencyID = mpe.ConstituencyID
GROUP BY
	Country;

-- Quantity of Members of Parliament by party

SELECT
	COUNT(MPID) AS [Members_of_Parliament],
	('All parties') AS [Party],
	100 AS [Percentage]
FROM MPS
UNION ALL
SELECT
	Members_of_Parliament,
	Party,
	100 * [Members_of_Parliament] / SUM(Members_of_Parliament) OVER () AS [Percentage]
FROM (
	SELECT
		COUNT(MPID) AS [Members_of_Parliament],
		Party 
	FROM MPs
	GROUP BY Party) AS PartyPercentage
ORDER BY Members_of_Parliament DESC;

-- Most popular party by region

WITH Party_cte AS (
	SELECT
		mp.Party,
		Region,
		RANK() OVER (PARTITION BY Region ORDER BY COUNT(Party) DESC) AS RK,
		COUNT(Party) AS Quantity_of_MPs
	FROM MPsExpenditure AS mpe
		INNER JOIN MPs AS mp ON mpe.MPID = mp.MPID
		INNER JOIN Regions AS r ON mpe.ConstituencyID = r.ConstituencyID
	GROUP BY
		Party,
		Region
)
SELECT TOP 10
	Party,
	Region,
	Quantity_of_MPs
FROM Party_cte
WHERE RK = 1
ORDER BY Quantity_of_MPs DESC;

----MPs names, parties and constituency

SELECT
	mpe.MPID,
	m.MPname,
	m.Party,
	r.Constituency,
	r.Type_Constituency,
	r.Region,
	r.Country
FROM MPsExpenditure AS mpe
	INNER JOIN MPs AS m ON mpe.MPID = m.MPID
	INNER JOIN Regions AS r ON mpe.ConstituencyID = r.ConstituencyID;

--Total budget and total spent

SELECT
	FORMAT(SUM(Office_Budget+Staffing_Budget+Winding_up_Budget+Accommodation_Budget),'C','en-gb') AS [Total_budget],
	FORMAT(SUM(Office_spend+Staffing_spend+Winding_up_spend+Accommodation_spend+Travel_and_subsistence_uncapped+Other_costs_uncapped),'C','en-gb') AS [Total_spend_plus_uncapped],
	FORMAT(SUM(Office_Budget),'C','en-gb') AS [Office_budget],
	FORMAT(SUM(Office_spend),'C','en-gb') AS [Office_spend],
	FORMAT(SUM(Staffing_budget),'C','en-gb') AS [Staffing_budget],
	FORMAT(SUM(Staffing_spend),'C','en-gb') AS [Staffing_spend],
	FORMAT(SUM(Winding_up_Budget),'C','en-gb') AS [Winding_up_budget],
	FORMAT(SUM(Winding_up_spend),'C','en-gb') AS [Winding_up_spend],
	FORMAT(SUM(Accommodation_budget),'C','en-gb') AS [Accommodation_budget],
	FORMAT(SUM(Accommodation_spend),'C','en-gb') AS [Accommodation_spend],
	FORMAT(SUM(Travel_and_subsistence_uncapped+Other_costs_uncapped),'C','en-gb') AS [Uncapped_spend]
FROM MPsExpenditure;

-- Remaining

SELECT
	FORMAT(SUM(Remaining_office_budget),'C','en-gb') AS Remaining_office_budget,
	FORMAT(SUM(Remaining_staffing_budget),'C','en-gb') AS Remaining_staffing_budget,
	FORMAT(SUM(Remaining_accommodation_budget),'C','en-gb') AS Remaining_accommodation_budget
FROM MPsExpenditure;

--MPs who did not meet the budget

WITH Total_cte AS (
	SELECT
		SpendID,
		mp.MPID,
		mp.MPname,
		mp.Party,
		r.Constituency,
		r.Country,
		ROUND(SUM((mpe.Office_budget) + (mpe.Staffing_budget) + (mpe.Winding_up_budget) +(mpe.Accommodation_budget)),2) AS [Total_Budget],
		ROUND(SUM((mpe.Office_spend) + (mpe.Staffing_spend) + (mpe.Winding_up_spend) + (mpe.Accommodation_spend)),2) AS [Total_Spent],
		ROUND(mpe.Travel_and_subsistence_uncapped + mpe.Other_costs_uncapped,2) AS [Expenditure_uncapped]
	FROM MPsExpenditure AS mpe
		INNER JOIN MPs AS mp ON mpe.MPID = mp.MPID
		INNER JOIN Regions AS r ON mpe.ConstituencyID = r.ConstituencyID
	GROUP BY 
		SpendID,
		mp.MPID,
		mp.MPname,
		mp.Party,
		r.Constituency,
		r.Country,
		mpe.Other_costs_uncapped,
		mpe.Travel_and_subsistence_uncapped
),
Total2_cte AS (
	SELECT
		Total_cte.*,
		CASE
			WHEN Total_cte.Total_Spent <= Total_cte.Total_Budget THEN 'MP meet the budget'
			ELSE 'MP did not meet the budget'
		END AS [Meet_the_budget?],
		ROUND((Total_Spent - Total_Budget),2) AS [Overspent]
	FROM Total_cte
)
SELECT *
FROM Total2_cte
WHERE [Meet_the_budget?] LIKE ('MP did not meet the budget');


SELECT
	SpendID,
	MPID,
	CASE
		WHEN Remaining_office_budget < 0 THEN CAST(Remaining_office_budget AS varchar)
		ELSE CONCAT('Not overspent - ',CAST(Remaining_office_budget AS varchar))
	END AS 'Overspent_on_the_office_budget?',
	CASE
		WHEN Remaining_staffing_budget < 0 THEN CAST(Remaining_staffing_budget AS varchar)
		ELSE CONCAT('Not overspent - ',CAST(Remaining_staffing_budget AS varchar))
	END AS 'Overspent_on_the_staffing_budget?',
	CASE
		WHEN Remaining_accommodation_budget < 0 THEN CAST(Remaining_accommodation_budget AS varchar)
		ELSE CONCAT('Not overspent - ',CAST(Remaining_accommodation_budget AS varchar))
	END AS 'Overspent_on_the_accommodation_budget?',
	CASE
		WHEN Remaining_winding_up_budget < 0 THEN CAST(Remaining_winding_up_budget AS varchar)
		ELSE CONCAT('Not overspent - ',CAST(Remaining_winding_up_budget AS varchar)) 
	END AS 'Overspent_on_the_winding_up_budget?'
FROM MPsExpenditure
WHERE MPID = 1392

-- Top 10 MPs in total expenditure

SELECT
	TOP 10 SpendID,
	mp.MPname,
	mp.Party,
	r.Constituency,
	r.Country,
	ROUND(SUM((mpe.Office_budget) + (mpe.Staffing_budget) + (mpe.Winding_up_budget) +(mpe.Accommodation_budget)),2) AS [Total_Budget],
	ROUND(SUM((mpe.Office_spend) + (mpe.Staffing_spend) + (mpe.Winding_up_spend) + (mpe.Accommodation_spend)),2) AS [Total_Spent],
	ROUND(SUM(mpe.Travel_and_subsistence_uncapped + mpe.Other_costs_uncapped),2) AS [Expenditure_uncapped]
FROM MPsExpenditure AS mpe
	INNER JOIN MPs AS mp ON mpe.MPID = mp.MPID
	INNER JOIN Regions AS r ON mpe.ConstituencyID = r.ConstituencyID
GROUP BY 
	SpendID,
	mp.MPname,
	mp.Party,
	r.Constituency,
	r.Country
ORDER BY [Total_Spent] DESC;


-- Maximum spent by category

	--Office
SELECT TOP 3
	mp.MPID,
	MPName,
	Party,
	Constituency,
	Region,
	Country,
	Office_Budget,
	ROUND(MAX(Office_Spend),2) AS [Max_spent],
	Reason_for_office_budget_set
FROM MPsExpenditure AS mpe
	INNER JOIN MPs AS mp ON mpe.MPID = mp.MPID
	INNER JOIN Regions AS rg ON mpe.ConstituencyID = rg.ConstituencyID
GROUP BY
	mp.MPID,
	MPName,
	Party,
	Constituency,
	Country,
	Region,
	Office_Budget,
	Reason_for_office_budget_set
ORDER BY [Max_spent] DESC;

	--Staffing
SELECT TOP 3
	mp.MPID,
	MPName,
	Party,
	Constituency,
	Region,
	Country,
	Staffing_Budget,
	ROUND(MAX(Staffing_spend),2) AS [Max_spent],
	Reason_for_staffing_budget_set
FROM MPsExpenditure AS mpe
	INNER JOIN MPs AS mp ON mpe.MPID = mp.MPID
	INNER JOIN Regions AS rg ON mpe.ConstituencyID = rg.ConstituencyID
GROUP BY
	mp.MPID,
	MPName,
	Party,
	Constituency,
	Region,
	Country,
	Staffing_Budget,
	Reason_for_staffing_budget_set
ORDER BY [Max_spent] DESC;

	--Accommodation
SELECT TOP 3
	mp.MPID,
	MPName,
	Party,
	Constituency,
	Region,
	Country,
	Accommodation_Budget,
	ROUND(MAX(Accommodation_spend),2) AS [Max_spent],
	Reason_for_accommodation_budget_set
FROM MPsExpenditure AS mpe
	INNER JOIN MPs AS mp ON mpe.MPID = mp.MPID
	INNER JOIN Regions AS rg ON mpe.ConstituencyID = rg.ConstituencyID
GROUP BY
	mp.MPID,
	MPName,
	Party,
	Constituency,
	Region,
	Country,
	Accommodation_Budget,
	Reason_for_accommodation_budget_set
ORDER BY [Max_spent] DESC;

	--Uncapped
SELECT TOP 3
	mp.MPID,
	MPName,
	Party,
	Constituency,
	Region,
	Country,
	ROUND(MAX(Travel_and_subsistence_uncapped + Other_costs_uncapped),2) AS [Max_spent]
FROM MPsExpenditure AS mpe
	INNER JOIN MPs AS mp ON mpe.MPID = mp.MPID
	INNER JOIN Regions AS rg ON mpe.ConstituencyID = rg.ConstituencyID
GROUP BY
	mp.MPID,
	MPName,
	Party,
	Constituency,
	Region,
	Country
ORDER BY [Max_spent] DESC;

--Creation of budget tables with standard values (without budget adjustment to a time period or further requests)

CREATE TABLE Office_Budget (
	Office_Budget_ID int IDENTITY(1,1) PRIMARY KEY,
	Reason_for_office_budget_set nvarchar(100),
	Budget_Office float
)

WITH Office_budget_cte AS (
	SELECT DISTINCT TOP 2
		Reason_for_office_budget_set,
		Office_budget,
		LEN(Reason_for_office_budget_set) AS [Lenght]
	FROM MPsExpenditure
	WHERE Reason_for_office_budget_set NOT IN ('N/A')
	ORDER BY LEN(Reason_for_office_budget_set) ASC
)
INSERT INTO Office_Budget (Reason_for_office_budget_set, Budget_Office)
SELECT
	Reason_for_office_budget_set,
	Office_budget
FROM Office_budget_cte

	--See the tables
SELECT *
FROM Office_Budget
SELECT *
FROM Staffing_Budget
SELECT *
FROM Accommodation_Budget
SELECT *
FROM Winding_up_Budget

/* Following queries are basically the same process as above but applied for different categories*/
CREATE TABLE Staffing_Budget (
	Staffing_Budget_ID int IDENTITY(1,1) PRIMARY KEY,
	Reason_for_staffing_budget_set nvarchar(100),
	Budget_Staffing float
)

WITH Staffing_budget_cte AS (
	SELECT DISTINCT TOP 2
		Reason_for_staffing_budget_set,
		Staffing_budget,
		LEN(Reason_for_staffing_budget_set) AS [Lenght]
	FROM MPsExpenditure
	WHERE Reason_for_staffing_budget_set NOT IN ('N/A')
	ORDER BY LEN(Reason_for_staffing_budget_set) ASC
)
INSERT INTO Staffing_Budget(Reason_for_Staffing_budget_set, Budget_Staffing)
SELECT
	Reason_for_staffing_budget_set,
	Staffing_Budget
FROM Staffing_budget_cte
	
CREATE TABLE Winding_up_Budget (
	Winding_up_ID int IDENTITY(1,1) PRIMARY KEY,
	Reason_for_winding_up_budget_set nvarchar(100),
	Budget_winding_up float
)

WITH Winding_up_budget_cte AS (
	SELECT DISTINCT TOP 2
		Reason_for_winding_up_budget_set,
		Winding_up_budget,
		LEN(Reason_for_winding_up_budget_set) AS [Lenght]
	FROM MPsExpenditure
	ORDER BY LEN(Reason_for_winding_up_budget_set) ASC
)
INSERT INTO Winding_up_Budget (Reason_for_winding_up_budget_set, Budget_winding_up)
SELECT
	Reason_for_winding_up_budget_set,
	Winding_up_budget
FROM Winding_up_budget_cte


CREATE TABLE Accommodation_Budget (
	Accommodation_Budget_ID int IDENTITY(1,1) PRIMARY KEY,
	Reason_for_accommodation_budget_set nvarchar(max),
	Budget_accommodation float
)

INSERT INTO Accommodation_Budget (Reason_for_accommodation_budget_set, Budget_accommodation)
SELECT
	Reason_for_accommodation_budget_set,
	Accommodation_Budget
FROM MPsExpenditure
WHERE Reason_for_accommodation_budget_set IN ('Standard budget for renting a property in the London area',
	'Standard budget for renting a property outside the London area',
	'Standard budget for renting a property in the London area, with an uplift to cover the cost of one dependant',
	'Standard budget for an MP who owns their property and is claiming the associated costs only (such as utilities)',
	'N/A')
GROUP BY 
	Reason_for_accommodation_budget_set,
	Accommodation_Budget
