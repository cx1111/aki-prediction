/* The top level script that generates and uses the individual views to extract the final cohort and features */

set search_path to mimiciii;


-- Generating materialized views from individual scripts

\ir demographics.sql -- run this first for the time windows in which to get covariates: 'startintime' and 'endintime'

\ir biomarkers.sql
\ir ckd.sql -- a covariate
\ir comorbidities.sql

\ir drugs.sql
\ir endstage.sql -- exclusion criteria
\ir fluids.sql
\ir rrt.sql
\ir urine.sql
\ir vitals.sql


-- Start with icustays>18h for age 18+ patients

-- Remove end stage renal disease cohort
drop materialized view if exists cohort0 cascade;
create materialized view cohort0 as(
select d.*
from demographics d
where d.hadm_id not in(
  select hadm_id from esrd
)
);

alter materialized view cohort0 drop column icustaynum;

COPY(
-- Add rrt label
with t0 as(
select c0.*, r.rrt 
from cohort0 c0
LEFT join rrt r
on c0.icustay_id = r.icustay_id),
-- Add sepsis information and mechanical ventilation
t1 as(
select t0.*, s.angus as sepsis, s.mech_vent
from t0
LEFT join angus_sepsis s
on t0.hadm_id=s.hadm_id),
-- Link CKD status
t2 as(
select t1.*, ck.ckd
from t1
left join ckd ck
on t1.icustay_id=ck.icustay_id), -- Some patients have multiple icu stays (in different hadm).
-- Add vitals
t3 as(
select t2.*, bp.heartrate_min, bp.heartrate_max, bp.heartrate_mean, bp.sysbp_min, bp.sysbp_max,
  bp.sysbp_mean, bp.diasbp_min, bp.diasbp_max, bp.diasbp_mean, bp.meanbp_min, bp.meanbp_max,
  bp.meanbp_mean, bp.resprate_min, bp.resprate_max, bp.resprate_mean
from t2
LEFT join bp
on bp.icustay_id = t2.icustay_id),
-- Add comorbidities
t4 as(
select t3.*, eq.congestive_heart_failure, eq.diabetes_uncomplicated, 
  eq.diabetes_complicated, eq.aids, eq.metastatic_cancer 
from t3
LEFT JOIN elixhauser_quan eq
on t3.hadm_id=eq.hadm_id),
-- Add urine
t5 as(
select t4.*, u.urineoutput
from t4
LEFT join urine u
on t4.icustay_id = u.icustay_id),
-- Add labs
t6 as(
select t5.*, labs.bicarbonate_min, labs.bicarbonate_max, labs.creatinine_min, labs.creatinine_max,
labs.lactate_min, labs.lactate_max, labs.potassium_min, labs.potassium_max, labs.sodium_min, labs.sodium_max,
labs.wbc_min, labs.wbc_max, labs.neutrophil_min, labs.neutrophil_max, labs.calcium_min, labs.calcium_max,
labs.phosphate_min, labs.phosphate_max, labs.crp_min, labs.crp_max, labs.esr_min, labs.esr_max
from t5
LEFT join labsfirstday labs
on t5.icustay_id = labs.icustay_id
)
-- Add drugs
select t6.*, 
case when t6.icustay_id in (select icustay_id from pressors) then 1
else 0
end as pressors
from t6
)
TO '/home/cx1111/Projects/aki-prediction/data_extraction/tables/data.csv' DELIMITER ',' CSV HEADER;

