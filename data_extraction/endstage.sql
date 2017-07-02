-- ESRD/ESRF/ESKD/ESKF

--select * from d_icd_diagnoses
--where long_title~*'end stage';

drop materialized view if exists cohort0 cascade;
create materialized view esrd as(
select hadm_id from diagnoses_icd -- Just this one: 'end stage renal disease'
where icd9_code = '5856'
);


