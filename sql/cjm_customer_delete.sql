with customer_delete as (
select
md5(concat(customer_id,customer_delete_dtm)) as event_id,
customer_id,
customer_delete_dtm as event_dtm,
'delete' as event_name,
customer_delete_dtm as meta_timestamp,
'raw.customer_delete' as meta_process_name
from raw.customer_delete
where customer_delete_dtm > coalesce((select max(meta_timestamp) from max_b.cjm_mart where meta_process_name = 'raw.customer_delete'), timestamp '1900-01-01')
)

insert into max_b.cjm_mart
select *
from customer_delete
