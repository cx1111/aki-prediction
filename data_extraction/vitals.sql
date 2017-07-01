-- Blood pressure and heart rate, respiratory rate, cvp

DROP MATERIALIZED VIEW IF EXISTS bp cascade;
CREATE MATERIALIZED VIEW bp AS(

SELECT DISTINCT subject_id, icustay_id, charttime, itemid, valuenum
FROM chartevents
WHERE valuenum IS NOT NULL AND itemid IN (220050, 220051, 220045) -- high, low, (arterial) hr
ORDER BY valuenum, icustay_id, charttime, itemid
);


