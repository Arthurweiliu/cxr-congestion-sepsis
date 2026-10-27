\set ON_ERROR_STOP on
-- 71_code_status.sql — 取 ICU 内 code status（DNR / DNI / comfort measures）
-- 前提：chartevents 上已有 itemid 部分索引（chatvents_itemid_cs_idx），否则全表扫描极慢

create index if not exists chartevents_itemid_cs_idx
  on mimiciv_icu.chartevents (itemid)
  where itemid in (223758, 228687);

drop table if exists cxr.code_status;
create unlogged table cxr.code_status as
select f.stay_id,
       max(case when c.value ~* '(DNR|DNI|comfort measure|no escalation|do not resuscitate)' then 1 else 0 end) as dnr_any,
       max(case when c.charttime <= f.intime + interval '24 hour'
                 and c.value ~* '(DNR|DNI|comfort measure|no escalation|do not resuscitate)' then 1 else 0 end) as dnr_24h,
       min(c.charttime) filter (where c.value ~* '(DNR|DNI|comfort measure|no escalation|do not resuscitate)') as first_limitation_time,
       count(*) as n_records
from cxr.final f
left join mimiciv_icu.chartevents c
  on c.stay_id = f.stay_id and c.itemid in (223758, 228687)
group by f.stay_id;

alter table cxr.code_status set logged;

select count(*) n_stays,
       sum(dnr_any) any_limitation,
       sum(dnr_24h) within_24h,
       round(100.0 * sum(dnr_24h) / count(*), 1) pct_24h
from cxr.code_status;

select value, count(*) n
from mimiciv_icu.chartevents
where itemid in (223758, 228687) and stay_id in (select stay_id from cxr.final)
group by value order by n desc limit 15;

\copy (select stay_id, dnr_24h as dnr, dnr_any, first_limitation_time, n_records from cxr.code_status) to 'F:/openclaw_workspace/CXR_congestion/data/code_status.csv' with (format csv, header true)
