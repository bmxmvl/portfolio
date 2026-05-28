insert into max_b.cjm_mart
select
md5(concat((raw_data::jsonb ->> 'uid')::varchar, (raw_data::jsonb -> 'registration_details' ->> 'registration_dtm')::varchar)) AS event_id,
(raw_data::jsonb ->> 'uid')::varchar AS customer_id,
(raw_data::jsonb -> 'registration_details' ->> 'registration_dtm')::timestamp AS event_dtm,
'registration' AS event_name,
insert_timestamp AS meta_timestamp,
'raw.customer' as meta_process_name
from raw.customer
where insert_timestamp > coalesce((select max(meta_timestamp) from max_b.cjm_mart where meta_process_name = 'raw.customer'),timestamp '1900-01-01')
