\set ON_ERROR_STOP on

alter table cxr.base add column if not exists fb24_mlkg double precision;
alter table cxr.base add column if not exists frontal int;

update cxr.base b set fb24_mlkg = f.fb24_mlkg
from rvgap.fb_all f where f.stay_id = b.stay_id;

update cxr.base b set frontal = v.fr
from cxr.film fi
join (
  select study_id, max(case when viewposition in ('AP','PA') then 1 else 0 end) as fr
  from mimiciv_cxr.metadata group by 1
) v on v.study_id = fi.study_id
where b.stay_id = fi.stay_id;

\copy (select * from cxr.base) to 'F:/openclaw_workspace/CXR_congestion/data/base.csv' with (format csv, header true)

select count(*) n, count(fb24_mlkg) has_fb24, count(frontal) has_frontal, sum(frontal) frontal_n
from cxr.base where cong_hybrid is not null and fb72_mlkg is not null;
