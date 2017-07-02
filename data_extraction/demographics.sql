/* Demographics of patients over 18 with icustay lengths over 18h */


-- Height and weight, taken from https://github.com/MIT-LCP/mimic-code/blob/401132f256aff1e67161ce94cf0714ac1d344f5c/demographics/postgres/HeightWeightQuery.sql
DROP MATERIALIZED VIEW IF EXISTS heightweight CASCADE;
CREATE MATERIALIZED VIEW heightweight
AS
WITH FirstVRawData AS
  (SELECT c.charttime,
    c.itemid,c.subject_id,c.icustay_id,
    CASE
      WHEN c.itemid IN (762, 763, 3723, 3580, 3581, 3582, 226512)
        THEN 'WEIGHT'
      WHEN c.itemid IN (920, 1394, 4187, 3486, 3485, 4188, 226707)
        THEN 'HEIGHT'
    END AS parameter,
    -- Ensure that all weights are in kg and heights are in centimeters
    CASE
      WHEN c.itemid   IN (3581, 226531)
        THEN c.valuenum * 0.45359237
      WHEN c.itemid   IN (3582)
        THEN c.valuenum * 0.0283495231
      WHEN c.itemid   IN (920, 1394, 4187, 3486, 226707)
        THEN c.valuenum * 2.54
      ELSE c.valuenum
    END AS valuenum
  FROM chartevents c
  WHERE c.valuenum   IS NOT NULL
  -- exclude rows marked as error
  AND c.error IS DISTINCT FROM 1
  AND ( ( c.itemid  IN (762, 763, 3723, 3580, -- Weight Kg
    3581,                                     -- Weight lb
    3582,                                     -- Weight oz
    920, 1394, 4187, 3486,                    -- Height inches
    3485, 4188                                -- Height cm
    -- Metavision
    , 226707 -- Height, cm
    , 226512 -- Admission Weight (Kg)

    -- note we intentionally ignore the below ITEMIDs in metavision
    -- these are duplicate data in a different unit
    -- , 226531 -- Admission Weight (lbs.)
    -- , 226707 -- Height (inches)
    )
  AND c.valuenum <> 0 )
    ) )
  --)

  --select * from FirstVRawData
, SingleParameters AS (
  SELECT DISTINCT subject_id,
         icustay_id,
         parameter,
         first_value(valuenum) over
            (partition BY subject_id, icustay_id, parameter
             order by charttime ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)
             AS first_valuenum,
         MIN(valuenum) over
            (partition BY subject_id, icustay_id, parameter
            order by charttime ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)
            AS min_valuenum,
         MAX(valuenum) over
            (partition BY subject_id, icustay_id, parameter
            order by charttime ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)
            AS max_valuenum
    FROM FirstVRawData

--   ORDER BY subject_id,
--            icustay_id,
--            parameter
  )
--select * from SingleParameters
, PivotParameters AS (SELECT subject_id, icustay_id,
    MAX(case when parameter = 'HEIGHT' then first_valuenum else NULL end) AS height_first,
    MAX(case when parameter = 'HEIGHT' then min_valuenum else NULL end)   AS height_min,
    MAX(case when parameter = 'HEIGHT' then max_valuenum else NULL end)   AS height_max,
    MAX(case when parameter = 'WEIGHT' then first_valuenum else NULL end) AS weight_first,
    MAX(case when parameter = 'WEIGHT' then min_valuenum else NULL end)   AS weight_min,
    MAX(case when parameter = 'WEIGHT' then max_valuenum else NULL end)   AS weight_max
  FROM SingleParameters
  GROUP BY subject_id,
    icustay_id
  )
--select * from PivotParameters
SELECT f.icustay_id,
  f.subject_id,
  ROUND( cast(f.height_first as numeric), 2) AS height_first,
  ROUND(cast(f.height_min as numeric),2) AS height_min,
  ROUND(cast(f.height_max as numeric),2) AS height_max,
  ROUND(cast(f.weight_first as numeric), 2) AS weight_first,
  ROUND(cast(f.weight_min as numeric), 2)   AS weight_min,
  ROUND(cast(f.weight_max as numeric), 2)   AS weight_max

FROM PivotParameters f
ORDER BY subject_id, icustay_id;



-- Combine info in demographics table 
DROP MATERIALIZED view if exists demographics cascade;
CREATE materialized view demographics as(
WITH tmp as(
SELECT a.subject_id, p.gender, a.ethnicity,
	EXTRACT(EPOCH FROM(a.admittime-p.dob))/(365.25*24*3600) as age,
	a.hadm_id,
	a.diagnosis, p.dod_hosp as dod
FROM admissions a
INNER JOIN patients p
      ON a.subject_id = p.subject_id
), tmp0 as(
SELECT t.*,
       i.icustay_id, i.intime, i.outtime, i.los,
       i.intime - interval '6' hour as startintime, -- fuzzy intime. start of where to look for covariates
       i.intime + interval '6' hour as endintime, -- limit time to where to look for covariates
       ROW_NUMBER() OVER(PARTITION BY t.hadm_id ORDER BY i.icustay_id DESC) AS icustaynum
FROM tmp t
INNER JOIN icustays i
ON t.hadm_id = i.hadm_id
   WHERE age>=18
   AND los>=0.75 -- 18 hours
)
select t.*, hw.weight_first as weight, hw.height_first as height
from tmp0 t
left join heightweight hw
on t.icustay_id = hw.icustay_id
where t.icustaynum = 1
ORDER BY subject_id, intime
); 
