insert into max_b.cjm_mart
select distinct on (c.customer_phone, event_dtm)
md5(concat(c.customer_phone, (s.raw_data::jsonb ->> 'dtm')::timestamp)) as event_id,
customer_id,
(s.raw_data::jsonb ->> 'dtm')::timestamp as event_dtm,
'sms' as event_name,
s.insert_timestamp as meta_timestamp,
'raw.crm_sms' as meta_process_name
from raw.crm_sms s
join core.customers c
on (s.raw_data::jsonb ->> 'phone')::varchar = c.customer_phone
and (s.raw_data::jsonb ->> 'dtm')::timestamp > registration_dtm
where s.insert_timestamp > coalesce((select max(meta_timestamp) from max_b.cjm_mart where meta_process_name = 'raw.crm_sms'), timestamp '1900-01-01')
order by c.customer_phone, event_dtm, registration_dtm desc
