create table if not exists max_b.kpi_mart (
order_month date,
order_day date,
fact_revenue_day numeric,
cum_revenue_in_month numeric,
plan_minimum_revenue numeric,
plan_reach_percent int,
plan_is_reached boolean
)
;

with agg_cte as (
select
date_trunc('month', order_date)::date as order_month,
order_date::date as order_day,
round(sum(max_b.calculate_revenue(amount::numeric, quantity::int, discount::numeric)), 2) as fact_revenue_day
from core.orders
where order_type = 'paid'
group by order_month, order_day
),

month_plan as (
select
order_month,
sum(fact_revenue_day) as fact_revenue_month
from agg_cte
group by order_month
),

agg_window_cte as (
select
ac.order_month,
ac.order_day,
ac.fact_revenue_day,
SUM(ac.fact_revenue_day) over(partition by ac.order_month order by ac.order_day asc) as cum_revenue_in_month,
mp.fact_revenue_month as plan_minimum_revenue
from agg_cte ac
left join month_plan mp on ac.order_month = mp.order_month + interval '1 month'
),

agg_window_percent_cte as (
select
order_month,
order_day,
fact_revenue_day,
cum_revenue_in_month,
plan_minimum_revenue,
((cum_revenue_in_month/plan_minimum_revenue)*100)::int as plan_reach_percent,
case 
	when ((cum_revenue_in_month/plan_minimum_revenue)*100)::int >= 100 then true
	else false
end as plan_is_reached
from agg_window_cte
)

insert into max_b.kpi_mart
select
order_month,
order_day,
fact_revenue_day,
cum_revenue_in_month,
plan_minimum_revenue,
plan_reach_percent,
plan_is_reached
from agg_window_percent_cte
where order_day < current_date 
  and order_day > coalesce((select max(order_day) from max_b.kpi_mart), '1900-01-01')
