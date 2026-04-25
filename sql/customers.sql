-- значение переменной OWNER рекомендуется в явном видео поменять на свою схему в рамках всех своих sql-скриптов
CREATE TABLE IF NOT EXISTS "{{ OWNER }}".customers (
customer_id varchar(50),
customer_name varchar(50),
birth_date date,
gender varchar(1),
customer_phone varchar(50),
customer_email varchar,
registration_dtm timestamp,
registration_source varchar(20),
device_data json,
meta_timestamp timestamp          
);

CREATE TEMPORARY TABLE customer_increment_tmp AS
WITH max_timestamp AS (
SELECT max(meta_timestamp) AS max_insert_timestamp
FROM "{{ OWNER }}".customers
)
SELECT DISTINCT ON ((raw_data::jsonb ->> 'uid')::varchar)
(raw_data::jsonb ->> 'uid')::varchar AS customer_id 
, (raw_data::jsonb ->> 'full_name')::varchar AS customer_name
, (raw_data::jsonb ->> 'gender')::varchar AS gender
, (raw_data::jsonb ->> 'birth_dtm')::date AS birth_dtm 
, (raw_data::jsonb ->> 'email')::varchar AS customer_email
, (raw_data::jsonb ->> 'phone')::varchar AS customer_phone
, (raw_data::jsonb -> 'registration_details' ->> 'registration_dtm')::timestamp AS registration_dtm
, (raw_data::jsonb -> 'registration_details' ->> 'regustration_source')::varchar AS registration_source
, (raw_data::jsonb ->> 'device')::json AS device_data
, insert_timestamp
FROM raw.customer
WHERE insert_timestamp > (SELECT COALESCE(max_insert_timestamp, '1900-01-01') FROM max_timestamp)
ORDER BY (raw_data::jsonb ->> 'uid')::varchar, insert_timestamp DESC
;

DELETE FROM "{{ OWNER }}".customers 
WHERE customer_id IN (SELECT customer_id FROM customer_increment_tmp)
;

INSERT INTO "{{ OWNER }}".customers 
SELECT 
customer_id
, customer_name
, birth_dtm
, CASE 
	WHEN gender ILIKE '%female%' THEN 'f' 
	WHEN gender ILIKE '%male%' THEN 'm'
	ELSE NULL
END AS gender
, customer_phone
, customer_email
, registration_dtm
, registration_source
, device_data
, insert_timestamp
FROM customer_increment_tmp
;
