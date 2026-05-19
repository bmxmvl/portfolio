create table if not exists max_b.ltv_mart (
customer_id varchar,
ltv decimal,
calculate_dtm timestamp,
is_actual boolean
)
;

with revenue_cte as (
select
customer_id,
sum(amount * quantity * (1 - (coalesce(discount::numeric, 0) / 100))) FILTER (WHERE order_type = 'paid') AS revenue
from core.orders
group by customer_id
),
costs_cte as (
select
customer_id,
sum(coalesce(cost::numeric, 0)) as costs
from max_b.crm_mart
group by customer_id
),
ltv_cte as (
select 
customer_id,
coalesce(revenue, 0) - coalesce(costs, 0) as ltv
from revenue_cte
full join costs_cte using (customer_id) 
),
updated AS (
UPDATE max_b.ltv_mart
SET is_actual = false
WHERE is_actual = true
RETURNING 1
)

INSERT INTO max_b.ltv_mart
SELECT
customer_id,
ltv,
now() AS calculate_dtm,
true  AS is_actual
FROM ltv_cte
