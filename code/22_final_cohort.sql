\set ON_ERROR_STOP on
drop table if exists cxr.final;
create table cxr.final as
with elig as (
  select b.*, ie.los, s3.suspected_infection_time,
         (b.subject_id in (select subject_id from cxr.vad_list)) as vad
  from cxr.base b
  join mimiciv_icu.icustays ie using (stay_id)
  join mimiciv_derived.sepsis3 s3 using (stay_id)
  where b.cong_hybrid is not null and b.fb72_mlkg is not null and b.death30 is not null
)
select *,
  case
    when weight_admit < 20 or weight_admit > 300 then 'ex_weight'
    when abs(fb72) > 20000 or fb72_mlkg > 300 or fb72_mlkg < -100 then 'ex_fb_implausible'
    when vad then 'ex_vad'
    when suspected_infection_time is null
      or suspected_infection_time < intime - interval '24 hour'
      or suspected_infection_time > intime + interval '24 hour' then 'ex_sepsis_timing'
  end as exclusion
from elig;

select coalesce(exclusion, 'INCLUDED') as step, count(*) as n, sum(death30) as deaths
from cxr.final group by 1 order by 1;

\copy (select * from cxr.final where exclusion is null) to 'F:/openclaw_workspace/CXR_congestion/data/final_cohort.csv' with (format csv, header true)
