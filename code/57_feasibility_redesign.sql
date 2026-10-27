\set ON_ERROR_STOP on

drop table if exists cxr.films_all;
create table cxr.films_all as
with m as (
  select distinct subject_id, study_id,
         to_timestamp(studydate::bigint::text, 'YYYYMMDD')
         + make_interval(hours => trunc(studytime/10000)::int,
                         mins  => trunc((studytime - trunc(studytime/10000)*10000)/100)::int,
                         secs  => (studytime - trunc(studytime/100)*100)::double precision) as ts
  from mimiciv_cxr.metadata
  where studydate is not null and studytime is not null
)
select c.stay_id, c.intime, ie.outtime, m.study_id, m.ts,
       floor(extract(epoch from (m.ts - c.intime))/86400.0) + 1 as icu_day
from cxr.final c
join mimiciv_icu.icustays ie on ie.stay_id = c.stay_id
join m on m.subject_id = c.subject_id
where c.exclusion is null
  and m.ts >= c.intime - interval '24 hour'
  and m.ts <  least(ie.outtime, c.intime + interval '14 day');

select 'stays' k, count(distinct stay_id)::text v from cxr.films_all
union all select 'stays with >=2 films', count(*)::text from (
  select stay_id from cxr.films_all group by 1 having count(*) >= 2) x
union all select 'stays with >=3 films', count(*)::text from (
  select stay_id from cxr.films_all group by 1 having count(*) >= 3) x
union all select 'total films', count(*)::text from cxr.films_all;

drop table if exists cxr.day_pairs;
create table cxr.day_pairs as
with days as (
  select c.stay_id, c.intime, ie.outtime, c.weight_admit, g.d as icu_day,
         c.intime + (g.d - 1) * interval '1 day' as d_start,
         least(c.intime + g.d * interval '1 day', ie.outtime) as d_end
  from cxr.final c
  join mimiciv_icu.icustays ie on ie.stay_id = c.stay_id
  cross join generate_series(1, 7) g(d)
  where c.exclusion is null
    and c.intime + (g.d - 1) * interval '1 day' < ie.outtime
), io as (
  select d.stay_id, d.icu_day,
         sum(i.amount) as intake,
         sum(o.value) as output
  from days d
  left join mimiciv_icu.inputevents i
    on i.stay_id = d.stay_id and i.starttime >= d.d_start and i.starttime < d.d_end
   and i.amountuom ilike 'ml' and coalesce(i.statusdescription,'') <> 'Rewritten'
  left join mimiciv_icu.outputevents o
    on o.stay_id = d.stay_id and o.charttime >= d.d_start and o.charttime < d.d_end
   and o.valueuom ilike 'ml'
  group by 1,2
), films as (
  select stay_id, icu_day from cxr.films_all group by 1,2
)
select d.stay_id, d.icu_day, d.weight_admit,
       io.intake, io.output,
       (io.intake - io.output) / nullif(d.weight_admit,0) as fb_mlkg,
       (films.stay_id is not null) as has_film
from days d
left join io on io.stay_id = d.stay_id and io.icu_day = d.icu_day
left join films on films.stay_id = d.stay_id and films.icu_day = d.icu_day;

select 'patient-days' k, count(*)::text v from cxr.day_pairs
union all select 'days with film', count(*)::text from cxr.day_pairs where has_film
union all select 'days with film AND fb', count(*)::text from cxr.day_pairs where has_film and fb_mlkg is not null
union all select 'days with film AND both IO', count(*)::text from cxr.day_pairs where has_film and intake is not null and output is not null
union all select 'stays with >=1 paired day', count(distinct stay_id)::text from cxr.day_pairs where has_film and fb_mlkg is not null;
