CREATE TABLE IF NOT EXISTS max_b.paid_orders (
	id varchar NULL,
	order_date timestamp NULL,
	customer_id varchar NULL,
	channel varchar NULL,
	amount float4 NULL,
	item_id varchar NULL,
	quantity int4 NULL,
	interface varchar NULL,
	birth_date date NULL,
	gender varchar(1) NULL,
	has_contact bool NULL,
	register_date date NULL,
	register_source text NULL,
	agent varchar NULL,
	meta_timestamp timestamp NULL
);

INSERT INTO max_b.paid_orders
SELECT 
o.id,
o.order_date,
o.customer_id,
o.channel,
o.amount,
o.item_id,
o.quantity,
o.interface,
c.birth_date,
c.gender,
COALESCE(customer_phone, customer_email) IS NOT NULL AS has_contact,
c.registration_dtm::date AS register_date,
CASE 
	WHEN registration_source LIKE '%app%' THEN 'app'
	WHEN registration_source IN ('wl', 'white_label') THEN 'wl'
	WHEN registration_source = 'subdomain' THEN 'subdomain'
	WHEN registration_source LIKE ('%main%') THEN 'main'
	WHEN registration_source = '' OR registration_source IS NULL THEN 'not defined'
	ELSE 'social'
END AS register_source,
(c.device_data::jsonb ->> 'agent')::varchar AS agent,
o.meta_timestamp
FROM core.orders o 
LEFT JOIN core.customers c 
ON o.customer_id = c.customer_id 
WHERE order_type = 'paid'
AND o.meta_timestamp > (SELECT COALESCE(max(meta_timestamp), '1900-01-01')::timestamp FROM max_b.paid_orders) 
