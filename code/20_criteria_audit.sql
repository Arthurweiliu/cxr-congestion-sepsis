\set ON_ERROR_STOP on
\pset footer off

-- 1. 是否为"首次 ICU 住院"（对比：首次脓毒症住院）
with s as (select subject_id, stay_id, intime from cxr.coh),
     f as (select subject_id, min(intime) as first_intime from mimiciv_icu.icustays group by 1)
select 'A. 首次脓毒症住院但非首次ICU住院' as item,
       count(*)::text as n
from s join f using (subject_id) where s.intime > f.first_intime

union all
-- 2. 脓毒症可疑感染时间与 ICU 入科的相对位置
select 'B. 可疑感染 <入科-24h',
       count(*)::text from cxr.coh c join mimiciv_derived.sepsis3 s using (stay_id)
 where s.suspected_infection_time < c.intime - interval '24 hour'
union all
select 'B. 可疑感染 入科±24h',
       count(*)::text from cxr.coh c join mimiciv_derived.sepsis3 s using (stay_id)
 where s.suspected_infection_time between c.intime - interval '24 hour' and c.intime + interval '24 hour'
union all
select 'B. 可疑感染 >入科+24h',
       count(*)::text from cxr.coh c join mimiciv_derived.sepsis3 s using (stay_id)
 where s.suspected_infection_time > c.intime + interval '24 hour'

union all
-- 3. ICU LOS < 72h（分析队列内）
select 'C. 分析队列 LOS<72h',
       count(*)::text
from cxr.base b join mimiciv_icu.icustays ie using (stay_id)
where b.cong_hybrid is not null and b.fb72_mlkg is not null and b.death30 is not null
  and ie.los < 3

union all
-- 4. 非正位片
select 'D. 非正位片（frontal=0）',
       count(*)::text from cxr.base
where cong_hybrid is not null and fb72_mlkg is not null and frontal = 0

union all
-- 5. 有胸片但未匹配到报告
select 'E. 有胸片但无报告',
       count(*)::text from cxr.base where has_film and not has_note

union all
-- 6. 体重缺失
select 'F. 体重缺失（分析队列内）',
       count(*)::text from cxr.base
where cong_hybrid is not null and fb72_mlkg is null and weight_admit is null

union all
-- 7. 可分类但液体平衡缺失
select 'G. 可分类但FB缺失',
       count(*)::text from cxr.base where cong_hybrid is not null and fb72_mlkg is null;
