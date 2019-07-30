--if object_id('MaxDebt') is not null
--begin
--     drop table MaxDebt
--end
;with CTE1
as
(
select distinct
       t.account_id as account_id
       ,l.amount as loan_amount
       ,sum(t.amount) over (partition by t.account_id, t.k_symbol,datepart(yy,t.[date])) as repaid
       ,t.k_symbol
       ,(l.amount - sum(t.amount) over (partition by t.account_id, t.k_symbol, datepart(yy,t.[date]))) as loan_unpaid
       ,datepart(yy,t.[date]) as loan_year
from dbo.trans as t
join dbo.loan as l
       on t.account_id = l.account_id
where t.k_symbol = 'UVER'
--order by account_id, [date]
)
,CTE2
as
(
select distinct
       account_id as account_id
       ,sum(amount) over (partition by account_id, [type],datepart(yy,[date])) as credit
       ,[type]
       ,datepart(yy, [date]) as credit_year 
from dbo.trans
where [type] = 'PRIJEM' and k_symbol <> 'UVER'
)
,CTE3
as
(
select distinct
       account_id as account_id
       ,sum(amount) over (partition by account_id, [type],datepart(yy,[date])) as debit
       ,[type]
       ,datepart(yy,[date]) as debit_year
from dbo.trans
where [type] in ('VYBER', 'VYDAJ')
)
select distinct
       CTE1.account_id
       ,cte1.loan_year
       ,sum(credit - (loan_unpaid + debit)) as yearly_oustanding_balance

--into MaxDebt

from CTE1
join CTE2
       on CTE1.account_id = CTE2.account_id and CTE1.loan_year=CTE2.credit_year
join CTE3
       on CTE2.account_id = CTE3.account_id and CTE2.credit_year = CTE3.debit_year

group by CTE1.account_id, CTE1.loan_year
order by account_id, CTE1.loan_year
