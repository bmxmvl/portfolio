truncate table max_b.pl_mart
;

with agg_cte as (
select 
order_date::date as order_date,
case 
	when channel is null or channel = '' then 'other'
	else channel
end as channel_name,
case 
	when order_type is null or order_type = '' then 'other'
	else order_type
end as order_type_name,
case 
	when interface is null or interface = '' then 'other'
	else interface
end as interface_name,
count(id) as orders_count,
count(distinct customer_id) as customers_count,
sum(quantity) as quantity_amount,
sum(max_b.calculate_revenue(amount::numeric, quantity::int, discount::numeric)) as revenue
from core.orders
group by order_date, channel_name, order_type_name, interface_name
),
agg_window_cte as (
select
*,
SUM(orders_count) over w as orders_count_day,
SUM(customers_count) over w as customers_count_day,
SUM(quantity_amount) over w as quantity_amount_day,
SUM(revenue) over w as revenue_day
from agg_cte
window w as (partition by order_date)
),
agg_window_percent_cte as (
select
*,
(orders_count::numeric/orders_count_day)*100 as orders_percent,
(customers_count::numeric/customers_count_day)*100 as customers_percent,
(quantity_amount::numeric/quantity_amount_day)*100 as quantity_percent,
(revenue::numeric/revenue_day)*100 as revenue_percent
from agg_window_cte
),
agg_window_percent_cost_cte as (
select 
awpc.*,
SUM(cm.cost::numeric) over(partition by order_date) as crm_cost
from agg_window_percent_cte awpc
left join max_b.crm_mart cm on awpc.order_date = cm.dtm::date
)

insert into max_b.pl_mart
select
order_date,
channel_name,
order_type_name,
interface_name,
orders_count,
customers_count,
quantity_amount,
revenue,
orders_count_day,
customers_count_day,
quantity_amount_day,
revenue_day,
orders_percent,
customers_percent,
quantity_percent,
revenue_percent,
crm_cost
from agg_window_percent_cost_cte
