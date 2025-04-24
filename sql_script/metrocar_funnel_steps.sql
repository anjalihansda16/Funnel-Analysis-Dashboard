select *
from Metrocar_download_and_signups 

select *
from Metrocar_ride_coordinate

select *
from Metrocar_requests_and_payments

select *
from Metrocar_reviews_table

select *
from Metrocar_User_Reviews

-- Data Wrangling for Viz 
--- Downloads funnel 
select
	0 as funnel_step,
	'Downloads' as funnel_name,
	platform, 
	age_range, 
	convert(date, download_ts) as download_date,
	count (distinct user_id) as user_count
into downloads
from Metrocar_download_and_signups
group by platform, age_range, convert(date, download_ts);


--- Sign Ups funnel 
select
	1 as funnel_step,
	'Sign Ups' as funnel_name,
	platform, 
	age_range, 
	convert(date, signup_ts) as download_date,
	count (distinct user_id) as user_count
into sign_ups
from Metrocar_download_and_signups
where signup_ts is not null
group by platform, age_range, convert(date, signup_ts);


--- Ride Requested funnel 
with cte as
(
select distinct
	r.user_id, 
	d.platform, 
	d.age_range,
	r.ride_id,
	r.driver_id,
	r.request_ts,
	r.accept_ts,
	r.pickup_location,
	r.pickup_ts,
	r.dropoff_ts,
	r.cancel_ts,
	r.purchase_amount_usd,
	r.charge_status
from Metrocar_requests_and_payments as r
left join Metrocar_download_and_signups as d
on r.user_id = d.user_id
)
select 
	2 as funnel_step,
	'Ride Requested' as funnel_name,
	platform,
	age_range,
	convert(date, request_ts) as download_date,
	count(user_id) as user_count
into ride_requested
from cte 
where request_ts is not null 
group by platform, age_range, convert(date, request_ts);


--- Ride Accepted funnel 
with cte as
(
select distinct
	r.user_id, 
	d.platform, 
	d.age_range,
	r.ride_id,
	r.driver_id,
	r.request_ts,
	r.accept_ts,
	r.pickup_location,
	r.pickup_ts,
	r.dropoff_ts,
	r.cancel_ts,
	r.purchase_amount_usd,
	r.charge_status
from Metrocar_requests_and_payments as r
left join Metrocar_download_and_signups as d
on r.user_id = d.user_id
)
select
	3 as funnel_stage,
	'Request Accepted' as funnel_name,
	platform, 
	age_range, 
	convert(date, accept_ts) as download,
	count(user_id) as user_count
into ride_accepted 
from cte
where accept_ts is not null
group by platform, age_range, convert(date, accept_ts);


--- Ride Completed funnel 
with cte as
(
select distinct
	r.user_id, 
	d.platform, 
	d.age_range,
	r.ride_id,
	r.driver_id,
	r.request_ts,
	r.accept_ts,
	r.pickup_location,
	r.pickup_ts,
	r.dropoff_ts,
	r.cancel_ts,
	r.purchase_amount_usd,
	r.charge_status
from Metrocar_requests_and_payments as r
left join Metrocar_download_and_signups as d
on r.user_id = d.user_id
)
select 
	4 as funnel_stage, 
	'Ride Completed' as funnel_name,
	platform, 
	age_range, 
	convert(date, dropoff_ts) as download_date, 
	count(user_id)  as user_count
into ride_completed
from cte
where dropoff_ts is not null
group by platform, age_range, convert(date, dropoff_ts); 


--- Payments funnel 
with cte as
(
select distinct
	r.user_id, 
	d.platform, 
	d.age_range,
	r.ride_id,
	r.driver_id,
	r.request_ts,
	r.accept_ts,
	r.pickup_location,
	r.pickup_ts,
	r.dropoff_ts,
	r.cancel_ts,
	r.purchase_amount_usd,
	r.charge_status
from Metrocar_requests_and_payments as r
left join Metrocar_download_and_signups as d
on r.user_id = d.user_id
)
select 
	5 as funnel_stage,
	'Payments' as funnel_name,
	platform, 
	age_range,
	convert(date, request_ts) as download_date,
	count(user_id) as user_count
into payments
from cte
where purchase_amount_usd is not null
group by platform, age_range, convert(date, request_ts);


--- Reviews funnel
with cte as
(
select distinct
	r.user_id, 
	d.platform, 
	d.age_range,
	r.ride_id,
	convert(date, rr.dropoff_ts) as download_date,
	r.rating
from Metrocar_reviews_table as r
left join Metrocar_download_and_signups as d
on r.user_id = d.user_id
left join Metrocar_requests_and_payments as rr
on r.user_id = rr.user_id
where rr.dropoff_ts is not null
)
select 
	6 as funnel_stage,
	'Reviews' as funnel_name,
	platform, 
	age_range,
	download_date,
	count(user_id) as user_count
into reviews
from cte
where rating is not null
group by platform, age_range, download_date;


---- Appending final tables for each funnel stage
drop table if exists Metrocar_Funnel_Data
create table Metrocar_Funnel_Data
(
funnel_step int,
funnel_name varchar(50), 
platform varchar(50),
age_range varchar(50), 
download_date date,
user_count int
)

insert into Metrocar_Funnel_Data(funnel_step, funnel_name, platform, age_range, download_date, user_count)
select * 
from downloads
union
select * 
from sign_ups
union
select *
from ride_requested
union
select *
from ride_accepted
union
select *
from ride_completed
union
select *
from payments
union 
select *
from reviews;


-- Final Table
select *
from Metrocar_Funnel_Data