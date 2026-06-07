create table if not exists max_b.crm_mart (
com_id varchar,
com_type varchar,
dtm timestamp,
contact varchar,
status varchar,
provider varchar,
type varchar,
rate varchar,
customer_id varchar,
cost numeric
);

with crm_cte as (
select
id as com_id,
'email' as com_type,
(raw_data::json ->> 'dtm')::timestamp as dtm,
(raw_data::json ->> 'email')::varchar as contact,
(raw_data::json ->> 'status')::varchar as status,
(raw_data::json ->> 'provider')::varchar as provider,
(raw_data::json ->> 'type')::varchar as type,
null::varchar as rate
from raw.crm_email
where (raw_data::json ->> 'dtm')::timestamp > coalesce((select max(dtm) from max_b.crm_mart where com_type = 'email'), timestamp '1900-01-01' )

union all

select
id as com_id,
'sms' as com_type,
(raw_data::json ->> 'dtm')::timestamp as dtm,
(raw_data::json ->> 'phone')::varchar as contact,
(raw_data::json ->> 'status')::varchar as status,
(raw_data::json ->> 'provider')::varchar as provider,
(raw_data::json ->> 'type')::varchar as type,
(raw_data::json ->> 'rate')::varchar as rate
from raw.crm_sms
where (raw_data::json ->> 'dtm')::timestamp > coalesce((select max(dtm) from max_b.crm_mart where com_type = 'sms'), timestamp '1900-01-01')
),

deleted_customers as (
select customer_id
from raw.customer_delete
),

active_customers as (
select
customer_id,
customer_email,
customer_phone,
registration_dtm
from core.customers
where not exists (
	select 1 from deleted_customers d
	where d.customer_id = customers.customer_id
)
),

crm_customer_id_cte as (
select
*
from (
select
com_id,
com_type,
dtm,
contact,
status,
provider,
type,
rate,
row_number() over(partition by a.contact order by b.registration_dtm desc) as dtm_rn
from crm_cte a
left join active_customers b on a.contact = b.customer_email
	and b.registration_dtm < a.dtm
where a.com_type = 'email'

union all

select
com_id,
com_type,
dtm,
contact,
status,
provider,
type,
rate,
row_number() over(partition by a.contact order by b.registration_dtm desc) as dtm_rn
from crm_cte a
left join active_customers b on a.contact = b.customer_phone
	and b.registration_dtm < a.dtm
where a.com_type = 'sms'
) c
where dtm_rn = 1
),

crm_customer_id_cost_cte as (
select
d.com_id,
d.com_type,
d.dtm,
d.contact,
d.status,
d.provider,
d.type,
d.rate,
d.customer_id,
e.cost
from crm_customer_id_cte d
left join max_b.crm_costs e 
	on case 
	when concat(extract(year from d.dtm)::int, 'Q', extract(quarter from d.dtm)::int) > (select max(quarter) from max_b.crm_costs)
	then '2026Q1'
	else concat(extract(year from d.dtm)::int, 'Q', extract(quarter from d.dtm)::int)
	end = e.quarter
    and d.com_type = e.com_type
    and d.type = e.type
    and coalesce(d.rate, '') = e.rate
)

insert into max_b.crm_mart
select
select
com_id,
com_type,
dtm,
contact,
status,
provider,
type,
rate,
customer_id,
cost
from crm_customer_id_cost_cte
