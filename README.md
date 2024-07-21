# Members of Parliament - Expenses

# Introduction

This project aims to analyse the annual budget, costs and claims made by each Member of Parliament in the United Kingdom in the period 2022 - 2023. In addition to the annual salary, MPs also receive expenses to cover the costs of running an office, employing staff, having somewhere to live in London or their constituency, and travelling between Parliament and their constituency. One Member of Parliament in the House of Commons represents a single constituency. Needless to say how adamant it is that MPs observe certain ethical standards in their duty as servants of the public and stewards of public resources. On the other hand, the scrutinity carried out on their expenses should also be reviwed by the public. Therefore, the purpose of this project is to break down their expenses, also considering their constituency and political party. 

# Dataset description

The dataset used in this project is mainly made up by the data avalaible on the IPSA website. IPSA, the Independent Parliamentary Standards Authority, is the independent body that regulates and administers the business costs and decides the pay and pensions of the elected MPs and their staff in the UK. Complementary to this data, it was necessary to create two other tables, with publicly available information, about the party each MP was affiliated, as well as the administrative geography of the constituency they represent.
Below you can find a diagram of the database used in this analysis.

+ The fact table contains the main information about each budget, the reason for that budget and its and expense (Office, staffing, winding-up, accommodation, travel and subsistence and other costs, the last two being unlimited) claimed by 661 MPs.
+ The MPs table covers the details about MPs, their names and party
+ Finally, the Region table presents the constituency they represent and some classification, as the designation, whether it is a borough constituency (predominantly urban area) or a county constituency (predominantly rural), the region and country to that belongs.

![MPs Diagram](https://github.com/user-attachments/assets/83870cfd-73d6-4e5d-8b85-52a037491a7d)

# Tools

+ Microsoft SQL Server Management Studios for data analysis - View [SQL Scripts](https://github.com/GleiAzevedo/Members-of-Parliament-Expenses/blob/main/MPs%20Expenditure%20queries.sql)
+ Power BI for data visualization - View [Power BI dashboard]()

# Key Questions Explored

1 - Quantity of Members of Parliament by country

```
SELECT 
	COUNT(MPID) AS [Quantity],
	Country
FROM Regions AS r
	INNER JOIN MPsExpenditure AS mpe ON r.ConstituencyID = mpe.ConstituencyID
GROUP BY
	Country;

```
The allocation of seats between each of the nations of the UK is calculated based on the proportion of the UK registered electorate. There are also periodically reviews reagarding the constituencies boundaries, resulting in necessary changes.

2 - Most popular party by region

```

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

```
> [!NOTE]
>It is important to keep in mind the period 2022-2023, prior to the 2024 general election, when the Conservative Party suffered a major defeat. The North-South line is also clear between the two parties, Conservative and Labor.

3 - Standard budgets (The following tables with standard values, without budget adjustment to a time period or further request, were createad and the codes used for it can be found on the SQL scripts folder)

+ Members of Parliament representing constituencies in the London area are provided with higher budgets, as the costs are also higher in the English capital.
+ Among the four budgets provided to the MPs, staffing is the highest one - £221,750 for non-London areas and £237,430 for London areas. To assist in their parliamentary work, each MP employs an average of four employees.
+ As the nature of the job requires them to represent their constituency in Westminster, all non-London MPs can claim accommodation costs to either stay in a hotel, rent accommodation, or claim associated costs for a property they own.
It must be remembered that the average monthly rent of a one bedroom property in the Westminster area in 2023 was around [£2,190](https://www.ons.gov.uk/visualisations/housingpriceslocal/E09000033/#rent_price) (£26,280 in a year) against the value of £25,080 budget stablished that year. It should be added to this budget an uplift to cover expenses for dependents, £5,720 per child, up to a maximum of three. 

4 - Total budget and total spend

```
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
FROM MPsExpenditure

```

+ Not only were none of the budgets spent completely, but there was a significant remaining for all budgets, the highest being the office allowance.
+ Although it can be subject of judgement, travels (under the uncapped spend) can also be claimed for MPs spouse, partner and dependants, > again so that they can maintain their family life and care for their dependants, according to [IPSA] (https://www.theipsa.org.uk/news/what-do-mps-spend-public-money-on).
26% Office, 16% Staffing, 23% Accommodation

5 - MPs who did not meet the budget

```
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

```

By the following code it is possible to see where the MP overspent.

```
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

```

Only one MP did not meet the budget and the overspending occurred in the office budget, by 6.7%.

6 - Top 10 MPs in total expenditure

```

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

```
In the list above we have 8 MPs from England constituencies, 1 from Northern Ireland and 1 from Scotland; 3 MPs filliated to the Conservative party, 2 to the Labour and 1 to the Labour/Co-operative, 2 to the Independent, 1 to the Scottish National Party and lastly, but in third place in the top 10, 1 MP filliated to the Social Democratic and Labour Party.

7 - Maximum spent by category

```

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

```

The result shows how nearly all the expenses are related to the London area. The exception to this happens in the uncapped expenses, where all MPs represent Scottish constituencies. It could be safe to say that the distance plays an important role in the travel expenses.
