-- This query pivots lab values taken in the first 6 hours of a patient's stay

-- Have already confirmed that the unit of measurement is always the same: null or the correct unit

DROP MATERIALIZED VIEW IF EXISTS labsfirstday CASCADE;
CREATE materialized VIEW labsfirstday AS
SELECT
  pvt.subject_id, pvt.hadm_id, pvt.icustay_id
  , min(CASE WHEN label = 'BICARBONATE' THEN valuenum ELSE null END) as BICARBONATE_min
  , max(CASE WHEN label = 'BICARBONATE' THEN valuenum ELSE null END) as BICARBONATE_max
  , min(CASE WHEN label = 'CREATININE' THEN valuenum ELSE null END) as CREATININE_min
  , max(CASE WHEN label = 'CREATININE' THEN valuenum ELSE null END) as CREATININE_max
  , min(CASE WHEN label = 'LACTATE' THEN valuenum ELSE null END) as LACTATE_min
  , max(CASE WHEN label = 'LACTATE' THEN valuenum ELSE null END) as LACTATE_max
  , min(CASE WHEN label = 'POTASSIUM' THEN valuenum ELSE null END) as POTASSIUM_min
  , max(CASE WHEN label = 'POTASSIUM' THEN valuenum ELSE null END) as POTASSIUM_max
  , min(CASE WHEN label = 'SODIUM' THEN valuenum ELSE null END) as SODIUM_min
  , max(CASE WHEN label = 'SODIUM' THEN valuenum ELSE null end) as SODIUM_max
  , min(CASE WHEN label = 'WBC' THEN valuenum ELSE null end) as WBC_min
  , max(CASE WHEN label = 'WBC' THEN valuenum ELSE null end) as WBC_max
  , min(CASE WHEN label = 'NEUTROPHIL' THEN valuenum ELSE null END) as NEUTROPHIL_min
  , max(CASE WHEN label = 'NEUTROPHIL' THEN valuenum ELSE null END) as NEUTROPHIL_max
  , min(CASE WHEN label = 'CALCIUM' THEN valuenum ELSE null END) as CALCIUM_min
  , max(CASE WHEN label = 'CALCIUM' THEN valuenum ELSE null END) as CALCIUM_max
  , min(CASE WHEN label = 'PHOSPHATE' THEN valuenum ELSE null END) as PHOSPHATE_min
  , max(CASE WHEN label = 'PHOSPHATE' THEN valuenum ELSE null end) as PHOSPHATE_max
  , min(CASE WHEN label = 'CRP' THEN valuenum ELSE null end) as CRP_min
  , max(CASE WHEN label = 'CRP' THEN valuenum ELSE null end) as CRP_max
  , min(CASE WHEN label = 'ESR' THEN valuenum ELSE null end) as ESR_min
  , max(CASE WHEN label = 'ESR' THEN valuenum ELSE null end) as ESR_max


FROM
( -- begin query that extracts the data
  SELECT ie.subject_id, ie.hadm_id, ie.icustay_id
  -- here we assign labels to ITEMIDs
  -- this also fuses together multiple ITEMIDs containing the same data
  , CASE
        WHEN itemid = 50882 THEN 'BICARBONATE'
        WHEN itemid = 50813 THEN 'LACTATE'
        WHEN itemid = 50971 THEN 'POTASSIUM'
        WHEN itemid = 50983 THEN 'SODIUM'
        WHEN itemid = 51301 THEN 'WBC'
        WHEN itemid = 51256 THEN 'NEUTROPHIL'
        WHEN itemid = 50893 THEN 'CALCIUM'
        WHEN itemid = 50970 THEN 'PHOSPHATE'
        WHEN itemid = 50889 THEN 'CRP'
        WHEN itemid = 51288 THEN 'ESR'
        WHEN itemid = 50912 THEN 'CREATININE'
      ELSE null
    END AS label
  , -- add in some sanity checks on the values
  -- the where clause below requires all valuenum to be > 0, so these are only upper limit checks
    CASE
      WHEN itemid = 50862 and valuenum >    10 THEN null -- g/dL 'ALBUMIN'
      WHEN itemid = 50868 and valuenum > 10000 THEN null -- mEq/L 'ANION GAP'
      WHEN itemid = 51144 and valuenum <     0 THEN null -- immature band forms, %
      WHEN itemid = 51144 and valuenum >   100 THEN null -- immature band forms, %
      WHEN itemid = 50882 and valuenum > 10000 THEN null -- mEq/L 'BICARBONATE'
      WHEN itemid = 50885 and valuenum >   150 THEN null -- mg/dL 'BILIRUBIN'
      WHEN itemid = 50806 and valuenum > 10000 THEN null -- mEq/L 'CHLORIDE'
      WHEN itemid = 50902 and valuenum > 10000 THEN null -- mEq/L 'CHLORIDE'
      WHEN itemid = 50912 and valuenum >   150 THEN null -- mg/dL 'CREATININE'
      WHEN itemid = 50809 and valuenum > 10000 THEN null -- mg/dL 'GLUCOSE'
      WHEN itemid = 50931 and valuenum > 10000 THEN null -- mg/dL 'GLUCOSE'
      WHEN itemid = 50810 and valuenum >   100 THEN null -- % 'HEMATOCRIT'
      WHEN itemid = 51221 and valuenum >   100 THEN null -- % 'HEMATOCRIT'
      WHEN itemid = 50811 and valuenum >    50 THEN null -- g/dL 'HEMOGLOBIN'
      WHEN itemid = 51222 and valuenum >    50 THEN null -- g/dL 'HEMOGLOBIN'
      WHEN itemid = 50813 and valuenum >    50 THEN null -- mmol/L 'LACTATE'
      WHEN itemid = 51265 and valuenum > 10000 THEN null -- K/uL 'PLATELET'
      WHEN itemid = 50822 and valuenum >    30 THEN null -- mEq/L 'POTASSIUM'
      WHEN itemid = 50971 and valuenum >    30 THEN null -- mEq/L 'POTASSIUM'
      WHEN itemid = 51275 and valuenum >   150 THEN null -- sec 'PTT'
      WHEN itemid = 51237 and valuenum >    50 THEN null -- 'INR'
      WHEN itemid = 51274 and valuenum >   150 THEN null -- sec 'PT'
      WHEN itemid = 50824 and valuenum >   200 THEN null -- mEq/L == mmol/L 'SODIUM'
      WHEN itemid = 50983 and valuenum >   200 THEN null -- mEq/L == mmol/L 'SODIUM'
      WHEN itemid = 51006 and valuenum >   300 THEN null -- 'BUN'
      WHEN itemid = 51300 and valuenum >  1000 THEN null -- 'WBC'
      WHEN itemid = 51301 and valuenum >  1000 THEN null -- 'WBC'
    ELSE le.valuenum
    END AS valuenum

  FROM icustays ie

  LEFT JOIN labevents le
    ON le.subject_id = ie.subject_id AND le.hadm_id = ie.hadm_id
    AND le.charttime BETWEEN (ie.intime - interval '6' hour) AND (ie.intime + interval '6' hour)
    AND le.ITEMID in
    (
      51301, 51256, 50813, 50983, 50971, 50882, 50893, 50970, 50889, 51288,50912
    )
    AND valuenum IS NOT null AND valuenum > 0 -- lab values cannot be 0 and cannot be negative
) pvt
GROUP BY pvt.subject_id, pvt.hadm_id, pvt.icustay_id
ORDER BY pvt.subject_id, pvt.hadm_id, pvt.icustay_id;

commit;
