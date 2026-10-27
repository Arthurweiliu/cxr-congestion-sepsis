\set ON_ERROR_STOP on

-- 第三种定义：IMPRESSION 优先；IMPRESSION 未描述肺时，回落到 FINDINGS
alter table cxr.base add column if not exists cong_hybrid int;

update cxr.base b
set cong_hybrid = case
  when b.cls_imp = 'pos_explicit' then 1
  when b.cls_imp in ('neg_explicit','clear_lungs') then 0
  when b.cls_full = 'pos_anywhere' then 1
  when b.cls_full in ('neg_explicit','clear_lungs') then 0
  when b.chex_edema = 1 then 1
  else null end;

\copy (select * from cxr.base) to 'F:/openclaw_workspace/CXR_congestion/data/base.csv' with (format csv, header true)

select 'primary(strict)' d, count(*)::text n from cxr.base where cong_primary is not null
union all select 'hybrid', count(*)::text from cxr.base where cong_hybrid is not null
union all select 'S1(findings-first)', count(*)::text from cxr.base where cong_s1 is not null
union all select 'primary + FB', count(*)::text from cxr.base where cong_primary is not null and fb72_mlkg is not null
union all select 'hybrid + FB', count(*)::text from cxr.base where cong_hybrid is not null and fb72_mlkg is not null
union all select 'S1 + FB', count(*)::text from cxr.base where cong_s1 is not null and fb72_mlkg is not null;
