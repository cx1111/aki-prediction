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
select d.*, d.
from demographics d
where d.hadm_id not in(
  select hadm_id from esrd
)
);

-- Add rrt label
drop materialized view if exists cohort1 cascade;
create materialized view cohort1 as(
select c0.*, r.rrt 
from cohort0 c0
inner join rrt r
on c0.icustay_id = r.icustay_id);


-- Add sepsis information
drop materialized view if exists cohort2 cascade;
create materialized view cohort2 as(
select c1.*, s.angus as sepsis
from cohort1 c1
inner join angus_sepsis s
on d.hadm_id=s.hadm_id);

-- Link CKD status
drop materialized view if exists cohort1 cascade;
create materialized view cohort1 as(
select c0.*,
	case when ck.subject_id IS NULL then False
	else True
	end as ckd
from cohort0 c0
LEFT JOIN ckd ck
on c0.subject_id=ck.subject_id); -- Some patients have multiple icu stays (in different hadm).




-----------------------  Filter Covariates  -------------------------------------



-- Keep only relevant cohort's creatinine. All rows have hadm_id. 
drop materialized view if exists creatinine_final cascade;
create materialized view creatinine_final as(
select *
from creatinine1
where icustay_id in(
select icustay_id
from cohort_final)
);



-- Keep only relevant cohort's map and fill in icustay
drop materialized view if exists map_final cascade;
create materialized view map_final as(
with tmp as(
select *
from map
where icustay_id in(
select icustay_id
from cohort_final)
), --  Removed about 2/3
tmp0 as( -- Isolate rows with icustay
   select *
   from tmp
   where icustay_id is not null
), tmp1 as( -- Isolate rows without icustay  
   select subject_id, charttime, itemid, valuenum
   from tmp
   where icustay_id is null
), tmp2 as( -- try to get icustay for missing rows 
   select t.subject_id, i.icustay_id as icustay_id, t.charttime, t.itemid, t.valuenum
   from tmp1 t
   inner join cohorticustays_final i
   on t.charttime between i.intime and i.outtime
   and t.subject_id = i.subject_id -- (with +/-12h)
), tmp3 as(
select * from tmp0 -- original with icustay
union
select * from tmp2 -- extra icustay filled. 
order by subject_id, icustay_id, charttime
)
select t.*, extract(epoch from(t.charttime-i.intimereal))/60 as min_from_intime
from tmp3 t
inner join cohorticustays_final i
on t.icustay_id = i.icustay_id
);


-- Keep only relevant cohort's urine and fill in missing icustay
drop materialized view if exists urine_final cascade;
create materialized view urine_final as(
with tmp as(
select *
from urine
where icustay_id in(
select icustay_id
from cohort_final)
), -- Removed about 2/3
tmp0 as( -- Isolate rows with icustay
   select *
   from tmp
   where icustay_id is not null
), tmp1 as( -- Isolate rows without icustay  
   select subject_id, hadm_id, charttime,  value
   from tmp
   where icustay_id is null
), tmp2 as( -- try to get icustay for missing rows 
   select t.subject_id, hadm_id, i.icustay_id as icustay_id, t.charttime, t.value
   from tmp1 t
   inner join cohorticustays_final i
   on t.charttime between i.intime and i.outtime
   and t.subject_id = i.subject_id -- (with +/-12h)
), tmp3 as(
select * from tmp0 -- original with icustay
union
select * from tmp2 -- extra icustay filled. 
order by subject_id, icustay_id, charttime
)
select t.*, extract(epoch from(t.charttime-i.intimereal))/60 as min_from_intime
from tmp3 t
inner join cohorticustays_final i
on t.icustay_id = i.icustay_id
);

-- Keep only relevant cohort's lactate
drop materialized view if exists lactate_final cascade;
create materialized view lactate_final as(
select *
from lactate
where icustay_id in(
select icustay_id
from cohort_final)
);

-- Keep only relevant cohort's vasopressor durations 
drop materialized view if exists vaso_final cascade;
create materialized view vaso_final as(
select *
from vasopressordurations
where icustay_id in(
select icustay_id
from cohort_final)
);

-- Every map, creatinine and urine from this point has an icustay_id.  



-------------------- Exporting Tables --------------------------
-- Creatinine
COPY(
  SELECT icustay_id, min_from_intime, valuenum as value
  FROM creatinine_final
  WHERE valuenum is not null
  ORDER BY icustay_id, min_from_intime
)
TO '/home/cx1111/Projects/aki-prediction/data_extraction/tables/creatinine.csv' DELIMITER ',' CSV HEADER;

-- Map
COPY(
  SELECT icustay_id, min_from_intime, itemid, valuenum as value
  FROM map_final
  WHERE valuenum is not null
  ORDER BY icustay_id, min_from_intime
)
TO '/home/cx1111/Projects/aki-prediction/data_extraction/tables/map.csv' DELIMITER ',' CSV HEADER;

-- Urine
COPY(
  SELECT icustay_id, min_from_intime, value
  FROM urine_final
  WHERE value is not null
  ORDER BY icustay_id, min_from_intime
)
TO '/home/cx1111/Projects/aki-prediction/data_extraction/tables/urine.csv' DELIMITER ',' CSV HEADER;


-- Demographics, lactate, vasopressor durations. There are commas in notes so use tab separated 
COPY(
  SELECT c.*, l.max_val as max_lactate, v.vaso_duration, v.vaso_frac 
  FROM cohort_final c
  LEFT join lactate_final l
  ON c.icustay_id = l.icustay_id
  LEFT join vaso_final v
  ON c.icustay_id = v.icustay_id
  ORDER BY subject_id, hadm_id, icustay_id
)
TO '/home/cx1111/Projects/aki-prediction/data_extraction/tables/cohort.tsv' DELIMITER E'\t' HEADER CSV;


-- Admission creatinines
COPY(
  SELECT *
  FROM admission_creatinine 
  where icustay_id in(
  select icustay_id
  from cohort_final)
)
TO '/home/cx1111/Projects/aki-prediction/data_extraction/tables/admission_creatinine.csv' DELIMITER ',' CSV HEADER;


-----------------------------------------------------------------
