\set ON_ERROR_STOP on
\timing on

drop schema if exists cxr cascade;
create schema cxr;

-- ============ 1. 队列：Sepsis-3 首次 ICU 住院、成人 ============
create table cxr.coh as
with base as (
  select s.subject_id, s.stay_id, s.sofa_score,
         ie.intime, ie.hadm_id,
         p.gender,
         (p.anchor_age + (extract(year from ie.intime) - p.anchor_year))::int as age,
         adm.deathtime, adm.hospital_expire_flag, p.dod,
         row_number() over (partition by s.subject_id order by ie.intime) as rn
  from mimiciv_derived.sepsis3 s
  join mimiciv_icu.icustays ie on ie.stay_id = s.stay_id
  join mimiciv_hosp.admissions adm on adm.hadm_id = ie.hadm_id
  join mimiciv_hosp.patients p on p.subject_id = s.subject_id
  where s.sepsis3
)
select subject_id, stay_id, sofa_score, intime, hadm_id, gender, age,
       deathtime, hospital_expire_flag, dod
from base where rn = 1 and age >= 18;

-- ============ 2. 胸片（±24h）============
create table cxr.film as
with m as (
  select distinct subject_id, study_id,
         to_timestamp(studydate::bigint::text, 'YYYYMMDD')
         + make_interval(
             hours => trunc(studytime / 10000)::int,
             mins  => trunc((studytime - trunc(studytime / 10000) * 10000) / 100)::int,
             secs  => (studytime - trunc(studytime / 100) * 100)::double precision
           ) as ts
  from mimiciv_cxr.metadata
  where studydate is not null and studytime is not null
), c as (
  select c2.stay_id, c2.subject_id, c2.intime, m.study_id, m.ts,
         ch.edema, ch.pleural_effusion, ch.cardiomegaly, ch.consolidation, ch.no_finding,
         row_number() over (partition by c2.stay_id
                            order by abs(extract(epoch from (m.ts - c2.intime)))) as rn
  from cxr.coh c2
  join m on m.subject_id = c2.subject_id
  join mimiciv_cxr.chexpert ch on ch.study_id = m.study_id and ch.subject_id = m.subject_id
  where m.ts between c2.intime - interval '24 hour' and c2.intime + interval '24 hour'
)
select stay_id, subject_id, intime, study_id, ts, edema, pleural_effusion,
       cardiomegaly, consolidation, no_finding
from c where rn = 1;

-- ============ 3. 匹配胸片报告 ============
create table cxr.note as
with r0 as (
  select f.stay_id, f.ts, f.edema, r.charttime, r.text,
         row_number() over (partition by f.stay_id
                            order by abs(extract(epoch from (r.charttime - f.ts)))) as rn
  from cxr.film f
  join mimiciv_note.radiology r
    on r.subject_id = f.subject_id
   and r.charttime between f.ts - interval '2 hour' and f.ts + interval '2 hour'
  where r.text ~* '(chest|thorax)'
    and r.text !~* '(computed tomography|CT HEAD|CT CHEST|CT ABDOMEN|MRI)'
)
select stay_id, ts, edema, charttime, text from r0 where rn = 1;

-- ============ 4. 文本分类（IMPRESSION 级 + 全文级）============
create table cxr.cls as
select stay_id, ts, edema as chex_edema, text,
       (text ~* 'impression') as has_impression,
       case when text ~* 'impression'
            then substring(text from '(?is).*impression.*$')
            else text end as imp_text
from cxr.note;

alter table cxr.cls add column cls_imp text;
alter table cxr.cls add column cls_full text;

update cxr.cls set cls_imp = case
  when imp_text ~* '(no|without|absent|clear of|resolved|negative for)[^.]{0,60}(edema|oedema)' then 'neg_explicit'
  when imp_text ~* '(edema|oedema)' then 'pos_explicit'
  when imp_text ~* '(clear lungs|lungs are clear|lung fields are clear|no focal consolidation|no consolidation|no acute pulmonary|no pleural effusion|no pneumothorax|no acute cardiopulmonary|unremarkable)' then 'clear_lungs'
  else 'unknown' end;

update cxr.cls set cls_full = case
  when text ~* '(no|without|absent|clear of|resolved|negative for)[^.]{0,60}(edema|oedema)' then 'neg_explicit'
  when text ~* '(edema|oedema)' then 'pos_anywhere'
  when text ~* '(clear lungs|lungs are clear|lung fields are clear|no focal consolidation|no consolidation|no acute pulmonary|no pleural effusion|no pneumothorax|no acute cardiopulmonary|unremarkable)' then 'clear_lungs'
  else 'unknown' end;

-- ============ 5. 协变量 ============
create table cxr.vaso as
select c.stay_id, 1 as vaso24
from cxr.coh c
join mimiciv_icu.inputevents i
  on i.stay_id = c.stay_id
 and i.itemid in (221906,221289,221662,221749,222315)
 and i.starttime < c.intime + interval '24 hour'
group by 1;

create table cxr.vent as
select distinct v.stay_id, 1 as vent24
from cxr.coh c
join mimiciv_derived.ventilation v on v.stay_id = c.stay_id
where v.ventilation_status = 'InvasiveVent'
  and v.starttime < c.intime + interval '24 hour';

-- ============ 6. 汇总表（含全部 25,596 例，便于画流程图）============
create table cxr.base as
select
  c.stay_id, c.subject_id, c.age, c.gender, c.sofa_score, c.intime, c.hadm_id,
  c.deathtime, c.dod, c.hospital_expire_flag,
  (f.stay_id is not null) as has_film,
  (n.stay_id is not null) as has_note,
  cl.has_impression, cl.cls_imp, cl.cls_full,
  cl.chex_edema,
  case
    when cl.cls_imp = 'pos_explicit' then 1
    when cl.cls_imp in ('neg_explicit','clear_lungs') then 0
    when cl.cls_imp = 'unknown' and cl.chex_edema = 1 then 1
    else null end as cong_primary,
  case
    when cl.cls_full = 'pos_anywhere' then 1
    when cl.cls_full in ('neg_explicit','clear_lungs') then 0
    when cl.cls_full = 'unknown' and cl.chex_edema = 1 then 1
    else null end as cong_s1,
  fb.fb72_mlkg, fb.fb72, fb.weight_admit, fb.out72, fb.in72,
  case when fb.out72 is not null and fb.weight_admit > 0
        and fb.out72 >= 0.3 * fb.weight_admit * 72
       then 1 else 0 end as output_complete,
  l.lactate_max,
  coalesce(v.vaso24, 0) as vaso24,
  coalesce(vn.vent24, 0) as vent24,
  coalesce(ch.congestive_heart_failure, 0) as hf,
  coalesce(ch.renal_disease, 0) as ckd,
  ch.charlson_comorbidity_index as cci,
  case when (c.deathtime is not null and c.deathtime <= c.intime + interval '30 day')
        or (c.dod is not null and c.dod <= (c.intime + interval '30 day')::date)
       then 1 else 0 end as death30,
  case when (c.deathtime is not null and c.deathtime <= c.intime + interval '90 day')
        or (c.dod is not null and c.dod <= (c.intime + interval '90 day')::date)
       then 1 else 0 end as death90,
  c.hospital_expire_flag as death_hosp
from cxr.coh c
left join cxr.film f on f.stay_id = c.stay_id
left join cxr.cls  cl on cl.stay_id = c.stay_id
left join cxr.note n on n.stay_id = c.stay_id
left join rvgap.fb_all fb on fb.stay_id = c.stay_id
left join mimiciv_derived.first_day_bg_art l on l.stay_id = c.stay_id
left join cxr.vaso v on v.stay_id = c.stay_id
left join cxr.vent vn on vn.stay_id = c.stay_id
left join mimiciv_derived.charlson ch on ch.hadm_id = c.hadm_id;

\copy (select * from cxr.base) to 'F:/openclaw_workspace/CXR_congestion/data/base.csv' with (format csv, header true)

-- ============ 7. 流程图计数 ============
select '1 sepsis3 stays' t, count(*)::text v from mimiciv_derived.sepsis3 where sepsis3
union all select '2 first stay, adult', count(*)::text from cxr.coh
union all select '3 CXR +-24h', count(*)::text from cxr.base where has_film
union all select '4 matched chest report', count(*)::text from cxr.base where has_note
union all select '5 classified (primary)', count(*)::text from cxr.base where cong_primary is not null
union all select '6 + FB available', count(*)::text from cxr.base where cong_primary is not null and fb72_mlkg is not null
union all select '7 final analytic', count(*)::text from cxr.base where cong_primary is not null and fb72_mlkg is not null and cci is not null
union all select 'S1 classified', count(*)::text from cxr.base where cong_s1 is not null
union all select 'S1 + FB', count(*)::text from cxr.base where cong_s1 is not null and fb72_mlkg is not null
union all select 'output_complete=1', count(*)::text from cxr.base where output_complete = 1;
