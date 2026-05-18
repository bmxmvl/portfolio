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
cost varchar
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
limit 100000
),
crm_customer_id_cte as (
select
*
from (
select 
*,
row_number() over(partition by a.contact order by registration_dtm desc) as dtm_rn
from crm_cte a
left join core.customers b on a.contact = case 
	when a.com_type = 'sms' then b.customer_phone 
	else b.customer_email
	end
	and b.registration_dtm < a.dtm
	and customer_id not in (select customer_id from raw.customer_delete)
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
left join max_b.crm_costs e on concat(extract(year from d.dtm)::int, 'Q', extract(quarter from d.dtm)::int) = e.quarter
    and d.com_type = e.com_type
    and d.type = e.type
    and coalesce(d.rate, '') = e.rate
)
insert into max_b.crm_mart
select *
from crm_customer_id_cost_cte
