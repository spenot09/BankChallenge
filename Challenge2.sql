/****** Script for SelectTopNRows command from SSMS  ******/
/*
I need a table with:
	max consecutive days (calculated above)-> need to window across client IDs. 
	age,
	age bin,
	client_id
*/


;with 
cte 
as 
(
SELECT
	MIN([Date]) AS range_start, 
    MAX([Date]) AS range_end,
    account_id
FROM (
	SELECT [Date], account_id,
		DATEDIFF(DAY, '20000101', [Date]) - 
		dense_rank() OVER(partition by account_id ORDER BY [Date]) AS grp
	FROM dbo.transactions AS A) AS T
	GROUP BY grp, account_id), 
	cte1 as (select account_id, Range_Start, Range_End, 
	DATEDIFF(day, Range_Start, Range_End) as [Days], 
	ROW_NUMBER() over (partition by account_id order by datediff(day, Range_Start, Range_End) DESC) as Row from cte
),age_bin_col
as
(
  SELECT 
	[client_id],
	date_of_birth,
	datepart(yy,[date_of_birth]) peak,
	case
		when datepart(yy,[date_of_birth])<1910 then 0
		when datepart(yy,[date_of_birth])<1920 then 10
		when datepart(yy,[date_of_birth])<1930 then 20
		when datepart(yy,[date_of_birth])<1940 then 30
		when datepart(yy,[date_of_birth])<1950 then 40
		when datepart(yy,[date_of_birth])<1960 then 50
		when datepart(yy,[date_of_birth])<1970 then 60
		when datepart(yy,[date_of_birth])<1980 then 70
		when datepart(yy,[date_of_birth])<1990 then 80
		when datepart(yy,[date_of_birth])<1990 then 90
	end age_bin

	
  FROM [Bank].[dbo].[client_cleansed]
  )

select
	 c.issued,
	 d.disp_id,
	 d.client_id,
	 d.account_id,
	 cte1.[Days],
	 cte1.range_start,
	 cte1.range_end,
	 c.card_id,
	 ag.age_bin as decade_born_in,
	 ag.date_of_birth
	 into #temp
from dbo.credit_card c --this join statement ensures that only valid credit card transactions are viewed.
join dbo.disposition d
on c.disp_id = d.disp_id
join cte1 
on d.account_id = cte1.account_id
join age_bin_col ag
on d.client_id = ag.client_id
where Row = 1
order by cte1.[days] desc

/****** Script for SelectTopNRows command from SSMS  ******/
SELECT 
      max([Days]) consecutive_days,
	  stdev([Days]) std_days
      ,[decade_born_in]
FROM #temp
group by decade_born_in
order by consecutive_days desc