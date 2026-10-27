\set ON_ERROR_STOP on

with base as (
  select b.*, ie.los, s.suspected_infection_time,
         (b.subject_id in (select subject_id from cxr.vad_list)) as vad
  from cxr.base b
  join mimiciv_icu.icustays ie using (stay_id)
  join mimiciv_derived.sepsis3 s using (stay_id)
  where b.cong_hybrid is not null and b.fb72_mlkg is not null and b.death30 is not null
),
step0 as (select * from base),
step1 as (select * from step0 where not vad
            and weight_admit between 20 and 300
            and abs(fb72) <= 20000
            and fb72_mlkg between -100 and 300),
step2 as (select * from step1
            where suspected_infection_time between intime - interval '24 hour' and intime + interval '24 hour'),
step3 as (select * from step2 where los >= 3)
select 'S0 当前分析队列' s, count(*) n, sum(death30) deaths,
       count(*) filter (where cong_hybrid=1 and fb72_mlkg<=0) grpC, avg(los)::numeric(4,1) los
from step0
union all select 'S1 +清洗(VAD/体重/FB极端)', count(*), sum(death30),
       count(*) filter (where cong_hybrid=1 and fb72_mlkg<=0), avg(los)::numeric(4,1) from step1
union all select 'S2 +脓毒症时间锚定±24h', count(*), sum(death30),
       count(*) filter (where cong_hybrid=1 and fb72_mlkg<=0), avg(los)::numeric(4,1) from step2
union all select 'S3 +ICU LOS>=72h', count(*), sum(death30),
       count(*) filter (where cong_hybrid=1 and fb72_mlkg<=0), avg(los)::numeric(4,1) from step3;
