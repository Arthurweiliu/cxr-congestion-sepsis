\set ON_ERROR_STOP on
drop table if exists cxr.film_events;
create table cxr.film_events as
with films as (
  select f.stay_id, f.intime, f.study_id, f.ts, f.icu_day
  from cxr.films_all f
  join cxr.final c on c.stay_id = f.stay_id and c.exclusion is null
  where f.ts >= f.intime + interval '24 hour'
), ins as (
  select f.stay_id, f.study_id,
         sum(i.amount) as intake_pre24
  from films f join mimiciv_icu.inputevents i on i.stay_id = f.stay_id
   and i.starttime >= f.ts - interval '24 hour' and i.starttime < f.ts
  where i.amountuom ilike 'ml' and coalesce(i.statusdescription,'') <> 'Rewritten'
  group by 1,2
), outs as (
  select f.stay_id, f.study_id,
         sum(o.value) as output_pre24
  from films f join mimiciv_icu.outputevents o on o.stay_id = f.stay_id
   and o.charttime >= f.ts - interval '24 hour' and o.charttime < f.ts
  where o.valueuom ilike 'ml'
  group by 1,2
)
select f.stay_id, f.study_id, f.ts, f.icu_day,
       round((extract(epoch from (f.ts - f.intime))/3600.0)::numeric,1) as hours_from_intime,
       coalesce(ins.intake_pre24,0) as intake_pre24,
       coalesce(outs.output_pre24,0) as output_pre24,
       round(((coalesce(ins.intake_pre24,0) - coalesce(outs.output_pre24,0)) / nullif(c.weight_admit,0))::numeric,1) as fb_pre24_mlkg
from films f
join cxr.final c on c.stay_id = f.stay_id
left join ins on ins.stay_id = f.stay_id and ins.study_id = f.study_id
left join outs on outs.stay_id = f.stay_id and outs.study_id = f.study_id;

select count(*) films,
       count(distinct stay_id) stays,
       count(fb_pre24_mlkg) with_fb,
       round(percentile_cont(0.5) within group (order by fb_pre24_mlkg)::numeric,1) median_fb,
       round(avg(fb_pre24_mlkg)::numeric,1) mean_fb,
       sum(case when fb_pre24_mlkg > 0 then 1 else 0 end) positive
from cxr.film_events;

select icu_day, count(*) films from cxr.film_events group by 1 order by 1;

\copy (select * from cxr.film_events) to 'F:/openclaw_workspace/CXR_congestion/data/film_events.csv' with (format csv, header true)
