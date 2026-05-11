with crm_email as (
select distinct on (c.customer_email, event_dtm)
md5(concat(c.customer_email, (s.raw_data::jsonb ->> 'dtm')::timestamp)) as event_id,
customer_id,
(s.raw_data::jsonb ->> 'dtm')::timestamp as event_dtm,
'email' as event_name,
s.insert_timestamp as meta_timestamp,
'raw.crm_email' as meta_process_name
from raw.crm_email s
join core.customers c
on (s.raw_data::jsonb ->> 'email')::varchar = c.customer_email
and (s.raw_data::jsonb ->> 'dtm')::timestamp > registration_dtm
where s.insert_timestamp > coalesce((select max(meta_timestamp) from max_b.cjm_mart where meta_process_name = 'raw.crm_email'), timestamp '1900-01-01')
order by c.customer_email, event_dtm, registration_dtm desc
)

insert into max_b.cjm_mart
select *
from crm_email
