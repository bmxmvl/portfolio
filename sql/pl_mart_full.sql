truncate table max_b.pl_mart
;

with last_date_cte as (
select coalesce(max(order_date), date '1900-01-01') as last_order_date
from max_b.pl_mart
),
agg_cte as (
select 
order_date::date as order_date,
case 
    when lower(channel) in ('organic', 'organicsearch') then 'органика'
    when lower(channel) in ('partner', 'partnership') then 'партнёры'
    when lower(channel) = 'refferal' then 'реферал'
    else 'не определено'
end as channel_name,
case 
    when lower(order_type) = 'paid' then 'оплачен'
    when lower(order_type) = 'search' then 'не оплачен'
    else 'не определено'
end as order_type_name,
case 
    when lower(interface) = 'app' then 'приложение'
    when lower(interface) = 'web' then 'веб'
    else 'не определено'
end as interface_name,
count(id) as orders_count,
count(distinct customer_id) as customers_count,
sum(quantity) as quantity_amount,
sum(max_b.calculate_revenue(amount::numeric, quantity::int, discount::numeric)) as revenue
from core.orders co
group by order_date::date, channel_name, order_type_name, interface_name
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
cost_cte as (
select
dtm::date as order_date,
sum(cost::numeric) as crm_cost
from max_b.crm_mart
group by dtm::date
),
agg_window_percent_cost_cte as (
select 
*
from agg_window_percent_cte awpc
left join cost_cte cc using (order_date)
)

insert into max_b.pl_mart
select
*
from agg_window_percent_cost_cte
