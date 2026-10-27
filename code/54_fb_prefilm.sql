\set ON_ERROR_STOP on
drop table if exists cxr.fb_prefilm;
create table cxr.fb_prefilm as
with f as (
  select c.stay_id, c.intime, c.weight_admit, s.ts as film_ts
  from cxr.final c
  join cxr.film s on s.stay_id = c.stay_id
  where c.exclusion is null
), ins as (
  select f.stay_id,
         sum(i.amount) filter (where i.starttime >= f.film_ts - interval '24 hour'
                                 and i.starttime <  f.film_ts) as intake_pre,
         sum(i.amount) filter (where i.starttime >= f.intime
                                 and i.starttime <  f.film_ts) as intake_from_icu
  from f join mimiciv_icu.inputevents i on i.stay_id = f.stay_id
   and i.starttime >= f.film_ts - interval '24 hour' and i.starttime < f.film_ts
  where i.amountuom ilike 'ml' and coalesce(i.statusdescription,'') <> 'Rewritten'
  group by 1
), outs as (
  select f.stay_id,
         sum(o.value) filter (where o.charttime >= f.film_ts - interval '24 hour'
                                and o.charttime <  f.film_ts) as output_pre
  from f join mimiciv_icu.outputevents o on o.stay_id = f.stay_id
   and o.charttime >= f.film_ts - interval '24 hour' and o.charttime < f.film_ts
  where o.valueuom ilike 'ml'
  group by 1
)
select f.stay_id, f.film_ts,
       round((extract(epoch from (f.film_ts - f.intime))/3600.0)::numeric,1) as film_hours,
       coalesce(ins.intake_pre,0) as intake_pre,
       coalesce(outs.output_pre,0) as output_pre,
       round(((coalesce(ins.intake_pre,0) - coalesce(outs.output_pre,0)) / nullif(f.weight_admit,0))::numeric,1) as fb_pre24_mlkg
from f
left join ins on ins.stay_id = f.stay_id
left join outs on outs.stay_id = f.stay_id;

select count(*) n,
       count(fb_pre24_mlkg) with_fb,
       round(avg(fb_pre24_mlkg)::numeric,1) mean_fb,
       round(percentile_cont(0.5) within group (order by fb_pre24_mlkg)::numeric,1) median_fb,
       sum(case when fb_pre24_mlkg > 0 then 1 else 0 end) positive
from cxr.fb_prefilm;

\copy (select * from cxr.fb_prefilm) to 'F:/openclaw_workspace/CXR_congestion/data/fb_prefilm.csv' with (format csv, header true)
