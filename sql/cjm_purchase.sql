with purchase as (
select
(raw_data::jsonb ->> 'purchase_id')::varchar as event_id,
(raw_data::jsonb ->> 'customer_id')::varchar as customer_id,
(raw_data::jsonb ->> 'purchase_dtm')::timestamp as event_dtm,
'order' as event_name,
insert_timestamp as meta_timestamp,
'raw.purchase' as meta_process_name
from raw.purchase
where insert_timestamp > coalesce((select max(meta_timestamp) from max_b.cjm_mart where meta_process_name = 'raw.purchase'), timestamp '1900-01-01'))

insert into max_b.cjm_mart
select *
from purchase
