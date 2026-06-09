create table if not exists max_b.customers_mart_inc (
customer_id varchar(50),
first_name text,
last_name text,
birth_date date,
gender varchar(1),
customer_phone varchar(20),
customer_email varchar,
phone_is_confirmed bool,
email_is_confirmed bool,
registration_dtm timestamp,
registration_source varchar(20),
first_auth_method varchar,
first_auth_dtm timestamp,
last_auth_method varchar,
last_auth_dtm timestamp,
auth_methods text,
auth_count int8,
passport_series varchar,
passport_number varchar,
passport_valid_dtm varchar,
dl_series varchar,
dl_number varchar,
dl_valid_dtm varchar,
passport_all json,
dl_all json,
customer_delete_dtm timestamp
);


create table if not exists max_b.docs_timestamp (
last_timestamp timestamp
);


create temp table customer_id_increment as
select customer_id
from raw.customer_auth
where auth_date > (
    select coalesce(max(last_auth_dtm), '1900-01-01')::timestamp
    from max_b.customers_mart_inc
)
union 
select customer_id
from core.customers
where registration_dtm > (
    select coalesce(max(registration_dtm), '1900-01-01')::timestamp
    from max_b.customers_mart_inc
)
union
select (raw_data::jsonb ->> 'customer_id')::varchar as customer_id
from raw.customer_documents
where insert_timestamp > (
    select coalesce(max(last_timestamp), '1900-01-01')::timestamp
    from max_b.docs_timestamp
)
union
select customer_id
from raw.customer_delete
where customer_delete_dtm > (
    select coalesce(max(customer_delete_dtm), '1900-01-01')::timestamp
    from max_b.customers_mart_inc
);


create temp table customer_auth_pars as
select
    customer_id,
    auth_method,
    auth_date
from raw.customer_auth a
where exists (
    select 1 from customer_id_increment inc
    where a.customer_id = inc.customer_id
);

create temp table customer_documents_pars as
select
    (raw_data::jsonb ->> 'customer_id')::varchar as customer_id,
    (raw_data::jsonb ->> 'document_id')::varchar as document_id,
    (raw_data::jsonb ->> 'document_type')::varchar as document_type,
    (raw_data::jsonb ->> 'series')::varchar as series,
    (raw_data::jsonb ->> 'number')::varchar as number,
    (raw_data::jsonb ->> 'valid_dtm')::varchar as valid_dtm
from raw.customer_documents d
where exists (
    select 1 from customer_id_increment inc
    where (d.raw_data::jsonb ->> 'customer_id')::varchar = inc.customer_id
);

create temp table phone_email_flags as
select
    customer_id,
    bool_or(auth_method in ('sms', 'push', '2fa', 'mfa')) as phone_is_confirmed,
    bool_or(auth_method = 'email') as email_is_confirmed
from customer_auth_pars a
group by customer_id;

create temp table customer_increment as
with customers_cte as (
    select
        b.customer_id,
        split_part(customer_name, ' ', 1) as first_name,
        split_part(customer_name, ' ', 2) as last_name,
        birth_date,
        gender,
        customer_phone,
        customer_email,
        coalesce(f.phone_is_confirmed, false) as phone_is_confirmed,
        coalesce(f.email_is_confirmed, false) as email_is_confirmed,
        registration_dtm,
        registration_source
    from core.customers b
    left join phone_email_flags f using (customer_id)
    where exists (
        select 1 from customer_id_increment inc
        where b.customer_id = inc.customer_id
    )
),
customer_documents_ranked as (
    select
        customer_id, document_type, series, number, valid_dtm,
        row_number() over (partition by customer_id, document_type order by valid_dtm desc) as rn_desc
    from customer_documents_pars
),
customer_documents_agg as (
    select
        customer_id,
        json_agg(json_build_object('series', series, 'number', number, 'valid_dtm', valid_dtm))
            filter (where document_type = 'ru_passport')    as passport_all,
        json_agg(json_build_object('series', series, 'number', number, 'valid_dtm', valid_dtm))
            filter (where document_type = 'driver_license') as dl_all
    from customer_documents_pars
    group by customer_id
),
customer_documents_cte as (
    select
        ag.customer_id,
        rn1.series as passport_series, rn1.number as passport_number, rn1.valid_dtm as passport_valid_dtm,
        rn2.series as dl_series, rn2.number as dl_number, rn2.valid_dtm as dl_valid_dtm,
        ag.passport_all, ag.dl_all
    from customer_documents_agg ag
    left join customer_documents_ranked rn1 on rn1.customer_id = ag.customer_id and rn1.document_type = 'ru_passport' and rn1.rn_desc = 1
    left join customer_documents_ranked rn2 on rn2.customer_id = ag.customer_id and rn2.document_type = 'driver_license' and rn2.rn_desc = 1
),
customer_auth_agg as (
    select
        customer_id,
        string_agg(distinct nullif(auth_method, ''), ', ' order by nullif(auth_method, '')) as auth_methods,
        min(auth_date) as first_auth_dtm,
        max(auth_date) as last_auth_dtm,
        count(auth_date) as auth_count
    from customer_auth_pars
    group by customer_id
),
customer_auth_cte as (
    select
        ag.customer_id,
        p1.auth_method as first_auth_method,
        ag.first_auth_dtm,
        p2.auth_method as last_auth_method, 
        ag.last_auth_dtm,
        ag.auth_methods,
        ag.auth_count
    from customer_auth_agg ag
    join customer_auth_pars p1
        on p1.customer_id = ag.customer_id 
        and p1.auth_date = ag.first_auth_dtm
    join customer_auth_pars p2 
        on p2.customer_id = ag.customer_id 
        and p2.auth_date = ag.last_auth_dtm
)
select *
from customers_cte
left join customer_auth_cte using (customer_id)
left join customer_documents_cte using (customer_id)
left join raw.customer_delete d using (customer_id);

delete from max_b.customers_mart_inc m
where exists (
    select 1 from customer_increment inc
    where inc.customer_id = m.customer_id
);

insert into max_b.customers_mart_inc
select * from customer_increment;

truncate max_b.docs_timestamp;

insert into max_b.docs_timestamp
select
max(insert_timestamp)
from raw.customer_documents
