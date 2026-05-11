with customer_auth as (
select
md5(concat(customer_id, auth_date)) as event_id,
customer_id,
auth_date as event_dtm,
concat('auth ', auth_method) as event_name,
auth_date as meta_timestamp,
'raw.customer_auth' as meta_process_name
from raw.customer_auth
where auth_date > coalesce((select max(meta_timestamp) from max_b.cjm_mart where meta_process_name = 'raw.customer_auth'), timestamp '1900-01-01')
)

insert into max_b.cjm_mart
select *
from customer_auth
