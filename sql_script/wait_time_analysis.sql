select *
from Metrocar_requests_and_payments

-- Time differences between funnel stages 

select 
	ride_id,
	convert(date, request_ts) as ride_date,
	datediff(minute, request_ts, dropoff_ts)*60 as service_start_to_end,
	datediff(minute, request_ts, accept_ts)*60 as diff_request_accept,
	case when accept_ts is null then datediff(minute, request_ts, cancel_ts)*60 else null end as diff_request_cancel,
	datediff(minute, accept_ts, pickup_ts)*60 as diff_accept_pickup,
	datediff(minute, accept_ts, cancel_ts)*60 as diff_accept_cancel
into Metrocar_Service_Wait_Time
from Metrocar_requests_and_payments

-- Final Table
select *
from Metrocar_Service_Wait_Time