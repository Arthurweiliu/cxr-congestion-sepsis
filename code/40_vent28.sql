\set ON_ERROR_STOP on
drop table if exists cxr.vent28;
create table cxr.vent28 as
select c.stay_id,
       coalesce(sum(
         extract(epoch from (
           least(coalesce(v.endtime, c.intime + interval '28 day'), c.intime + interval '28 day')
           - greatest(v.starttime, c.intime)
         )) / 86400.0
       ) filter (where v.starttime < c.intime + interval '28 day'), 0) as vent_days
from cxr.final c
left join mimiciv_derived.ventilation v
  on v.stay_id = c.stay_id
 and v.ventilation_status = 'InvasiveVent'
 and v.starttime < c.intime + interval '28 day'
group by c.stay_id;

select count(*) n, count(*) filter (where vent_days > 0) ventilated,
       round(avg(vent_days)::numeric, 2) mean_days
from cxr.vent28;

\copy (select * from cxr.vent28) to 'F:/openclaw_workspace/CXR_congestion/data/vent28.csv' with (format csv, header true)
