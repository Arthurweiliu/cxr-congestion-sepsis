\set ON_ERROR_STOP on
set statement_timeout = '280s';

drop table if exists cxr.lac_bg;
create table cxr.lac_bg as
select c.stay_id,
       max(g.lactate) as lac_any,
       max(case when g.specimen = 'ART' then g.lactate end) as lac_art
from cxr.coh c
join mimiciv_derived.bg g
  on g.subject_id = c.subject_id
 and g.charttime between c.intime - interval '6 hour' and c.intime + interval '24 hour'
where g.lactate is not null and g.lactate > 0 and g.lactate < 30
group by 1;

alter table cxr.base add column if not exists lac_any double precision;
alter table cxr.base add column if not exists lac_art double precision;

update cxr.base b set lac_any = l.lac_any, lac_art = l.lac_art
from cxr.lac_bg l where b.stay_id = l.stay_id;

\copy (select * from cxr.base) to 'F:/openclaw_workspace/CXR_congestion/data/base.csv' with (format csv, header true)

select count(*) n, count(lac_any) has_any, count(lac_art) has_art, count(lactate_max) has_bg_art
from cxr.base where cong_hybrid is not null and fb72_mlkg is not null;
