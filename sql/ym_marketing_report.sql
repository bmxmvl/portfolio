create table if not exists max_b.ym_marketing_report (
    watchid varchar null,
    counteruseridhash varchar null,
    datetime timestamp null,
    referer varchar null,
    url varchar null,
    external_resource varchar null,
    page_title varchar null,
    device_type varchar null,
    event_type varchar null,
    meta_timestamp timestamp null,
    visitid varchar null,
    isnewuser boolean null,
    starturl varchar null,
    endurl varchar null,
    pageviews int null,
    visitduration int null,
    regioncountry varchar null,
    regioncity varchar null
);
with ym_hits_cte as (
select 
watchid,
counteruseridhash,
datetime::timestamp,
referer,
split_part(url, '?', 1) as url,
case
    when url like '%t.me/%' then 'tg'
    when url like '%forms.gle/%' then 'google forms'
    when url like '%github.com/%' then 'github'
    when url like '%disk.yandex.%' then 'yandex disk'
    when url like '%vk.com/%' then 'vk group'
    when url like '%instagram.com/%' then 'instagram'
    when url like '%youtube.com/%'
    or url like '%youtu.be/%' then 'youtube'
    when url like '%drive.google.%' then 'google drive'
    else 'other'
end as external_resource,
case
    when url like 'https://datastudy.ru/1%' then 'ОАД'
    when url = 'https://datastudy.ru/webinars' then 'Вебинары'
    when url = 'https://datastudy.ru/oferta' then 'Оферта'
    when url like '%#rec1771710121%' then 'SQL программа'
    when url like '%#rec1774936751%' then 'SQL оплата'
    when url like '%#rec1774669311%' then 'SQL формат занятий'
    when url like '%#rec1774786221%' then 'SQL отзывы'
    when url like '%#rec1771710081%' then 'SQL преимущества'
    when url like '%#rec1774944811%' then 'SQL стоимость'
    when url = 'https://datastudy.ru/quiz' then 'Квиз'
    when url = 'https://datastudy.ru/check_list' then 'Чек-лист'
    when url like 'https://datastudy.ru/%' then 'Главная'
    else 'other'
end as page_title,
case
    when devicecategory = '1' then 'laptop'
    when devicecategory = '2' then 'phone'
    else 'other'
end as device_type,
case
    when ispageview = '1' then 'view'
    when link = '1' then 'click'
    when artificial = '1' then 'artificial'
    else 'other'
end as event_type,
insert_dtm::timestamp as meta_timestamp
from raw.ym_hits
where insert_dtm::timestamp > coalesce(
    (select max(meta_timestamp) from max_b.ym_marketing_report), timestamp '1900-01-01'
    )
),

ym_visits_cte as (
select unnest(string_to_array(trim(both '[]' from watchids), ',')) as watchid,
visitid,
isnewuser::boolean,
starturl,
endurl,
pageviews::int,
visitduration::int,
regioncountry,
regioncity
FROM raw.ym_visits
)

insert into max_b.ym_marketing_report
select
watchid,
counteruseridhash,
datetime,
referer,
url,
external_resource,
page_title,
device_type,
event_type,
meta_timestamp,
visitid,
isnewuser,
starturl,
endurl,
pageviews,
visitduration,
regioncountry,
regioncity
from ym_hits_cte
left join ym_visits_cte using (watchid)
