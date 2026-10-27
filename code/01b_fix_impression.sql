\set ON_ERROR_STOP on

-- 修正：IMPRESSION 提取。原写法 substring(... '(?is).*impression.*$') 因左端贪婪匹配返回全文
update cxr.cls
set imp_text = regexp_replace(text, '(?is)^.*impression\s*:?', '')
where text ~* 'impression';

update cxr.cls set cls_imp = case
  when imp_text ~* '(no|without|absent|clear of|resolved|negative for)[^.]{0,60}(edema|oedema)' then 'neg_explicit'
  when imp_text ~* '(edema|oedema)' then 'pos_explicit'
  when imp_text ~* '(clear lungs|lungs are clear|lung fields are clear|no focal consolidation|no consolidation|no acute pulmonary|no pleural effusion|no pneumothorax|no acute cardiopulmonary|unremarkable)' then 'clear_lungs'
  else 'unknown' end;

update cxr.base b
set cls_imp = c.cls_imp,
    cong_primary = case
      when c.cls_imp = 'pos_explicit' then 1
      when c.cls_imp in ('neg_explicit','clear_lungs') then 0
      when c.cls_imp = 'unknown' and c.chex_edema = 1 then 1
      else null end
from cxr.cls c
where b.stay_id = c.stay_id;

\copy (select * from cxr.base) to 'F:/openclaw_workspace/CXR_congestion/data/base.csv' with (format csv, header true)

select 'impression extracted' t, count(*)::text v from cxr.cls where imp_text <> text
union all select 'classified primary', count(*)::text from cxr.base where cong_primary is not null
union all select 'primary + FB', count(*)::text from cxr.base where cong_primary is not null and fb72_mlkg is not null
union all select 'S1 + FB', count(*)::text from cxr.base where cong_s1 is not null and fb72_mlkg is not null
union all select 'primary≠S1', count(*)::text from cxr.base where cong_primary is not null and cong_s1 is not null and cong_primary <> cong_s1;

select cls_imp, count(*) from cxr.cls group by 1 order by 2 desc;
