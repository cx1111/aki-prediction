-- Find all patients with chronic kidney disease. Only subject id.

drop materialized view if exists ckd cascade;
create materialized view ckd as(
select distinct subject_id, icd9_code
from mimiciii.diagnoses_icd
where lower(icd9_code) like '585%'); -- 5417

