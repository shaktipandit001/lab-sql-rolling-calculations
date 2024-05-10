use sakila;
-- 1. Get number of monthly active customers.
with cte_active_customers as (
	select customer_id, convert(payment_date, date) as Activity_date,
		date_format(convert(payment_date,date), '%m') as Activity_Month,
		date_format(convert(payment_date,date), '%Y') as Activity_year
	from sakila.payment
)
select Activity_year, Activity_Month, count(distinct customer_id) as Active_customers
from cte_active_customers
group by Activity_year, Activity_Month;

-- 2. Active users in the previous month.
with cte1_active_customers as (
	select customer_id, convert(payment_date, date) as Activity_date,
		date_format(convert(payment_date,date), '%m') as Activity_Month,
		date_format(convert(payment_date,date), '%Y') as Activity_year
	from sakila.payment
), cte2_active_customers as (
	select Activity_year, Activity_Month, count(distinct customer_id) as Active_customers
	from cte1_active_customers
	group by Activity_year, Activity_Month
)
select Activity_year, Activity_month, Active_customers, 
   lag(Active_customers) over (order by Activity_year, Activity_Month) as Last_month
from cte2_active_customers;

-- 3. Percentage change in the number of active customers.
with cte1_active_customers as (
	select customer_id, convert(payment_date, date) as Activity_date,
		date_format(convert(payment_date,date), '%m') as Activity_Month,
		date_format(convert(payment_date,date), '%Y') as Activity_year
	from sakila.payment
), cte2_active_customers as (
	select Activity_year, Activity_Month, count(distinct customer_id) as Active_customers
	from cte1_active_customers
	group by Activity_year, Activity_Month
), cte_active_customers_prev as (
	select Activity_year, Activity_month, Active_customers, 
	   lag(Active_customers) over (order by Activity_year, Activity_Month) as Last_month
	from cte2_active_customers)
select *,
	(Active_customers - Last_month) as Difference,
    concat(round((Active_customers - Last_month)/Active_customers*100), "%") as Percent_Difference
from cte_active_customers_prev;

-- 4. Retained customers every month.

-- get the unique active customers per month
with cte_customers as (
	select customer_id, convert(payment_date, date) as Activity_date,
		date_format(convert(payment_date,date), '%m') as Activity_Month,
		date_format(convert(payment_date,date), '%Y') as Activity_year
	from sakila.payment
)
select distinct 
	customer_id as Active_id, 
	Activity_year, 
	Activity_month
from cte_customers
order by Active_id, Activity_year, Activity_month;

--  self join to find recurrent customers (users that made a transfer this month and also last month)
with cte_customers as (
	select customer_id, convert(payment_date, date) as Activity_date,
		date_format(convert(payment_date,date), '%m') as Activity_Month,
		date_format(convert(payment_date,date), '%Y') as Activity_year
	from sakila.payment
), retained_customers as (
	select distinct 
		customer_id as Active_id, 
		Activity_year, 
		Activity_month
	from cte_customers
	order by Active_id, Activity_year, Activity_month
)
select r1.Active_id, r1.Activity_year, r1.Activity_month, r2.Activity_month as Previous_month
from retained_customers r1
join retained_customers r2
on r1.Activity_year = r2.Activity_year -- To match the similar years. It is not perfect, is we wanted to make sure that, for example, Dez/1994 would connect with Jan/1995, we would have to do something like: case when rec1.Activity_month = 1 then rec1.Activity_year + 1 else rec1.Activity_year end
and r1.Activity_month = r2.Activity_month+1 -- To match current month with previous month. It is not perfect, if you want to connect Dezember with January we would need something like this: case when rec2.Activity_month+1 = 13 then 12 else rec2.Activity_month+1 end;
and r1.Active_id = r2.Active_id -- To get recurrent users.
order by r1.Active_id, r1.Activity_year, r1.Activity_month;

