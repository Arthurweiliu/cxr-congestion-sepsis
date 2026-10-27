\set ON_ERROR_STOP on
drop table if exists cxr.unknown_set;
create table cxr.unknown_set as
with elig as (
  select b.*, s3.suspected_infection_time,
         (b.subject_id in (select subject_id from cxr.vad_list)) as vad
  from cxr.base b
  join mimiciv_derived.sepsis3 s3 using (stay_id)
  where b.has_note
    and b.fb72_mlkg is not null
    and b.death30 is not null
)
select *
from elig
where weight_admit between 20 and 300
  and abs(fb72) <= 20000
  and fb72_mlkg between -100 and 300
  and not vad
  and suspected_infection_time between intime - interval '24 hour' and intime + interval '24 hour';

select 'total' k, count(*)::text v from cxr.unknown_set
union all select 'cong known', count(*)::text from cxr.unknown_set where cong_hybrid is not null
union all select 'cong unknown', count(*)::text from cxr.unknown_set where cong_hybrid is null;

\copy (select stay_id, subject_id, intime, age, gender, sofa_score, weight_admit, fb72, fb72_mlkg,
              fb24_mlkg, cong_hybrid, cong_s1, cong_primary, cls_imp, cls_full, chex_edema,
              lac_any, vent24, vaso24, hf, ckd, death30, death_hosp, output_complete
       from cxr.unknown_set) to 'F:/openclaw_workspace/CXR_congestion/data/unknown_set.csv' with (format csv, header true)
