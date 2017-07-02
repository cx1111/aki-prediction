-- Find all patients with chronic kidney disease. Only subject id.
/*    Non-specific code 585 Chronic kidney disease (ckd)
    Specific code 585.1 Chronic kidney disease, Stage I convert 585.1 to ICD-10-CM
    Specific code 585.2 Chronic kidney disease, Stage II (mild) convert 585.2 to ICD-10-CM
    Specific code 585.3 Chronic kidney disease, Stage III (moderate) convert 585.3 to ICD-10-CM
    Specific code 585.4 Chronic kidney disease, Stage IV (severe) convert 585.4 to ICD-10-CM
    Specific code 585.5 Chronic kidney disease, Stage V convert 585.5 to ICD-10-CM
    Specific code 585.6 End stage renal disease convert 585.6 to ICD-10-CM
    Specific code 585.9 Chronic kidney disease, unspecified convert 585.9 to ICD-10-CM
*/

drop materialized view if exists ckd cascade;
create materialized view ckd as(
select distinct subject_id, icd9_code
from mimiciii.diagnoses_icd
where icd9_code in ('5851', '5852', '5853', '5854', '5855')); -- 1184

