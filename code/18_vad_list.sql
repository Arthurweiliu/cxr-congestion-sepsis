\set ON_ERROR_STOP on
drop table if exists cxr.vad_list;
create table cxr.vad_list as
with a as (
  select distinct subject_id from cxr.base
  where cong_hybrid is not null and fb72_mlkg is not null and death30 is not null
)
select distinct a.subject_id
from a join mimiciv_hosp.diagnoses_icd d on d.subject_id = a.subject_id
where d.icd_code like 'V421%' or d.icd_code like 'Z941%'
   or d.icd_code like 'T862%' or d.icd_code like '99683%'
union
select distinct a.subject_id
from a join mimiciv_hosp.procedures_icd p on p.subject_id = a.subject_id
where p.icd_code like '3765%' or p.icd_code like '3766%'
   or p.icd_code like '02HA%' or p.icd_code like '02YA%';

\copy (select * from cxr.vad_list) to 'F:/openclaw_workspace/CXR_congestion/data/vad_transplant_subjects.csv' with (format csv, header true)
select count(*) from cxr.vad_list;
