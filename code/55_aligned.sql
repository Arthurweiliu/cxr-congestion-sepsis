\set ON_ERROR_STOP on
drop table if exists cxr.aligned;
create table cxr.aligned as
with f as (
  select c.stay_id, c.intime, c.weight_admit, s.ts as film_ts,
         extract(epoch from (s.ts - c.intime))/3600.0 as film_hours
  from cxr.final c join cxr.film s on s.stay_id = c.stay_id
  where c.exclusion is null
    and s.ts >= c.intime and s.ts <= c.intime + interval '24 hour'
), ins as (
  select f.stay_id, sum(i.amount) as intake
  from f join mimiciv_icu.inputevents i on i.stay_id = f.stay_id
   and i.starttime >= f.intime and i.starttime < f.film_ts
  where i.amountuom ilike 'ml' and coalesce(i.statusdescription,'') <> 'Rewritten'
  group by 1
), outs as (
  select f.stay_id, sum(o.value) as output
  from f join mimiciv_icu.outputevents o on o.stay_id = f.stay_id
   and o.charttime >= f.intime and o.charttime < f.film_ts
  where o.valueuom ilike 'ml'
  group by 1
)
select f.stay_id, round(f.film_hours::numeric,1) as film_hours,
       coalesce(ins.intake,0) as intake_ml, coalesce(outs.output,0) as output_ml,
       round(((coalesce(ins.intake,0)-coalesce(outs.output,0))/nullif(f.weight_admit,0))::numeric,1) as fb_before_film_mlkg
from f left join ins on ins.stay_id=f.stay_id left join outs on outs.stay_id=f.stay_id;

select count(*) n,
       round(percentile_cont(0.5) within group (order by film_hours)::numeric,1) median_hours,
       round(avg(fb_before_film_mlkg)::numeric,1) mean_fb,
       round(percentile_cont(0.5) within group (order by fb_before_film_mlkg)::numeric,1) median_fb,
       sum(case when fb_before_film_mlkg > 0 then 1 else 0 end) positive
from cxr.aligned;

\copy (select * from cxr.aligned) to 'F:/openclaw_workspace/CXR_congestion/data/aligned.csv' with (format csv, header true)
