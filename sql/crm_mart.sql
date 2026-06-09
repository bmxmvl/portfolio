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
cc.com_id,
cc.com_type,
cc.dtm,
cc.contact,
cc.status,
cc.provider,
cc.type,
cc.rate,
ac.customer_id,
row_number() over(partition by cc.contact order by ac.registration_dtm desc) as dtm_rn
from crm_cte cc
left join active_customers ac on cc.contact = ac.customer_email
	and ac.registration_dtm < cc.dtm
where cc.com_type = 'email'

union all

select
cc.com_id,
cc.com_type,
cc.dtm,
cc.contact,
cc.status,
cc.provider,
cc.type,
cc.rate,
ac.customer_id,
row_number() over(partition by cc.contact order by ac.registration_dtm desc) as dtm_rn
from crm_cte cc
left join active_customers ac on cc.contact = ac.customer_phone
	and ac.registration_dtm < cc.dtm
where cc.com_type = 'sms'
) a
where dtm_rn = 1
),

crm_customer_id_cost_cte as (
select
ccic.com_id,
ccic.com_type,
ccic.dtm,
ccic.contact,
ccic.status,
ccic.provider,
ccic.type,
ccic.rate,
ccic.customer_id,
cc.cost
from crm_customer_id_cte ccic
left join max_b.crm_costs cc 
	on case 
	when concat(extract(year from ccic.dtm)::int, 'Q', extract(quarter from ccic.dtm)::int) > (select max(quarter) from max_b.crm_costs)
	then '2026Q1'
	else concat(extract(year from ccic.dtm)::int, 'Q', extract(quarter from ccic.dtm)::int)
	end = cc.quarter
    and ccic.com_type = cc.com_type
    and ccic.type = cc.type
    and coalesce(ccic.rate, '') = cc.rate
)

insert into max_b.crm_mart 
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
