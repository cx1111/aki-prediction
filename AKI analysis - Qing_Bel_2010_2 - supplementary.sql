/**********************************The AKI analysis with Belinda *******************************************/
/*************************Changed previous analysis to study only adm_dt in 2010 patients and Version 2*******************/

/***check amount of dicharge summary during the years*****/
select distinct substring(encounter_id, 1,4) as adm_yyyy, count(encounter_id) as cnt
FROM t_discharge_summary
group by substring(encounter_id, 1,4)
order by substring(encounter_id, 1,4)

select distinct substring(encounter_id, 1,6) as adm_yyyymm, count(encounter_id) as cnt
FROM t_discharge_summary
where substring(encounter_id, 1,4) = '2012' or substring(encounter_id, 1,4) = '2011'
group by substring(encounter_id, 1,6)
order by substring(encounter_id, 1,6)



/***check the list of drugs under "aminoglycosides"*****/
/***Note NETILMICIN does not appear in the code form***/
SELECT  [drug_cd]
      ,[brand_cleaned]
      ,[ingred_cleaned]
      ,[drug_class]
      ,[type]
  FROM [Saphire].[dbo].[ct_common_drug]
  where [ingred_cleaned] in ('AMIKACIN','GENTAMICIN','STREPTOMYCIN','%NETILMICIN%','KANAMYCIN').
  -- All exist, but NETILMICIN

/*ADD: check the drugs of interest are truly given via systemic route***/
Select 
	t2.drug_inpat_serve_ingred_clean as drug_item_t,
	route_adm_t,
	count(distinct person_id) as patient_cnt,
	count(distinct tE.encounter_id) as encounter_cnt
From dbo.t_encounter tE,
	[saphire].dbo.t_inpatient_med_order t1
		LEFT JOIN [saphire].dbo.ct_common_dosage_form t3 on  t1.dosage_form_cd = t3.dosage_form_cd
		LEFT JOIN ct_common_drug t4 on t1.drug_inpat_order_clean_cd = t4.drug_cd
		LEFT JOIN ct_common_route_adm t5 on t1.route_adm_cd = t5.route_adm_cd,
	[saphire].dbo.t_inpatient_med_serving t2
Where tE.encounter_id = t1.encounter_id
	and tE.pat_type_cd = t1.pat_type_cd
	and t1.encounter_id = t2.encounter_id  
	and t1.order_id  = t2.order_id
	and t1.drug_inpat_order_ingred_clean = t2.drug_inpat_serve_ingred_clean
	and t1.drug_inpat_order_ingred_clean in ('AMIKACIN','GENTAMICIN','STREPTOMYCIN','NETILMICIN','KANAMYCIN')
	and t2.serving_status_cd not in ('EXCEPTION')    --confirm taken
	and dosage_form_t = 'INJECTION'   --confirm dosage form in INJECTION
	and route_adm_t != 'INTRAPERITONEAL'  --exclude INTRAPERITONEAL
	and tE.adm_dt between '2010-01-01' and '2010-12-31' -- test on only patients adm in 2010 
group by t2.drug_inpat_serve_ingred_clean, route_adm_t

/**Table 1.2**/
/****** Count no. patient who are on drug of Aminoglycosides*********/
Select 
	t2.drug_inpat_serve_ingred_clean as drug_item_t,
	count(distinct person_id) as patient_cnt,
	count(distinct tE.encounter_id) as encounter_cnt
From dbo.t_encounter tE,
	[saphire].dbo.t_inpatient_med_order t1
		LEFT JOIN [saphire].dbo.ct_common_dosage_form t3 on  t1.dosage_form_cd = t3.dosage_form_cd
		LEFT JOIN ct_common_drug t4 on t1.drug_inpat_order_clean_cd = t4.drug_cd
		LEFT JOIN ct_common_route_adm t5 on t1.route_adm_cd = t5.route_adm_cd,
	[saphire].dbo.t_inpatient_med_serving t2
Where tE.encounter_id = t1.encounter_id
	and tE.pat_type_cd = t1.pat_type_cd
	and t1.encounter_id = t2.encounter_id  
	and t1.order_id  = t2.order_id
	and t1.drug_inpat_order_ingred_clean = t2.drug_inpat_serve_ingred_clean
	and t1.drug_inpat_order_ingred_clean in ('AMIKACIN','GENTAMICIN','STREPTOMYCIN','NETILMICIN','KANAMYCIN')
	and t2.serving_status_cd not in ('EXCEPTION')    --confirm taken
	and dosage_form_t = 'INJECTION'   --confirm dosage form in INJECTION
	and route_adm_t != 'INTRAPERITONEAL'  --exclude INTRAPERITONEAL
	and tE.adm_dt between '2010-01-01' and '2010-12-31' -- test on only patients adm in 2010 
group by t2.drug_inpat_serve_ingred_clean


/***table 1.2 list out Version***/
/****** List all patient who are on drug of Aminoglycosides*********/
/*every order of aminoglycosides with the serving duration*/
Select  tE.person_id,
	tE.pat_type_cd,
	tE.encounter_id,
	t1.order_id,
	min(t2.serving_dt) serving_start_dt,
	max(t2.serving_dt) serving_end_dt,
	t1.drug_inpat_order_ingred_clean as drug_item_t
into  [Saphire_working].dbo.aminoglycosides_drugs_2010    --Need to delete the table from server before re-run
From [saphire].dbo.t_encounter tE,
	[saphire].dbo.t_inpatient_med_order t1
		LEFT JOIN [saphire].dbo.ct_common_dosage_form t3 on  t1.dosage_form_cd = t3.dosage_form_cd
		LEFT JOIN [saphire].dbo.ct_common_route_adm t4 on t1.route_adm_cd = t4.route_adm_cd,
	[saphire].dbo.t_inpatient_med_serving t2
Where tE.encounter_id = t1.encounter_id
	and tE.pat_type_cd = t1.pat_type_cd
	and t1.encounter_id = t2.encounter_id  
	and t1.order_id  = t2.order_id
	and t1.drug_inpat_order_ingred_clean = t2.drug_inpat_serve_ingred_clean
	and t1.drug_inpat_order_ingred_clean in ('AMIKACIN','GENTAMICIN','STREPTOMYCIN','NETILMICIN','KANAMYCIN')
	and t2.serving_status_cd not in ('EXCEPTION')    --confirm taken
	and dosage_form_t = 'INJECTION'   --confirm dosage form in INJECTION
	and route_adm_t != 'INTRAPERITONEAL'  --exclude INTRAPERITONEAL
	and tE.adm_dt between '2010-01-01' and '2010-12-31' -- test on only patients adm in 2010 
group by tE.person_id,
	tE.pat_type_cd,
	tE.encounter_id,
	t1.order_id,
	t1.drug_inpat_order_ingred_clean 


/*Conti. from above query**add dose information***/
select t1.person_id,
	   t1.pat_type_cd,
	   t1.encounter_id,
	   t1.order_id,
	   t1.serving_start_dt,
	   t1.serving_end_dt,
	    --serving_dur_hour      *skiped from sql, will add in excel from start and end dt
	   t1.drug_item_t,
	   t4.dosage_form_t,
	   t2.dose_t,
	   t2.freq_cd,
	   t3.route_adm_t ,
	   t2.infusion_rate,
	   t2.instruction
from  [Saphire_working].dbo.aminoglycosides_drugs_2010 t1
		LEFT JOIN [Saphire].dbo.t_inpatient_med_order t2 on t1.order_id = t2.order_id and t1.drug_item_t = t2.drug_inpat_order_ingred_clean
		LEFT JOIN [Saphire].dbo.ct_common_route_adm t3 on t2.route_adm_cd = t3.route_adm_cd
		LEFT JOIN [saphire].dbo.ct_common_dosage_form t4 on  t2.dosage_form_cd = t4.dosage_form_cd
order by person_id,encounter_id

/**Get out all patient_id with the drug_start_dt, adm_dt, and disch_dt that are on drug Aminoglycosides. **/
/***this table is for later use to get baseline and drug_start_dt infor**/
Select distinct
	person_id,
	tE.encounter_id,
	adm_dt,
	disch_dt,
    drug_inpat_order_ingred_clean,
	min(serving_dt) as drug_start_dt   --Logic: with in that adm period, the first day to take med.
--into [Saphire_working].dbo.Amino_records_2010    --Need to delete the table from server before re-run
From dbo.t_encounter tE,
	[saphire].dbo.t_inpatient_med_order t1
		LEFT JOIN [saphire].dbo.ct_common_dosage_form t3 on  t1.dosage_form_cd = t3.dosage_form_cd
		LEFT JOIN ct_common_drug t4 on t1.drug_inpat_order_clean_cd = t4.drug_cd
		LEFT JOIN ct_common_route_adm t5 on t1.route_adm_cd = t5.route_adm_cd,
	[saphire].dbo.t_inpatient_med_serving t2
Where tE.encounter_id = t1.encounter_id
	and tE.pat_type_cd = t1.pat_type_cd
	and t1.encounter_id = t2.encounter_id  
	and t1.order_id  = t2.order_id
	and t1.drug_inpat_order_ingred_clean = t2.drug_inpat_serve_ingred_clean
	and t1.drug_inpat_order_ingred_clean in ('AMIKACIN','GENTAMICIN','STREPTOMYCIN','NETILMICIN','KANAMYCIN')
	and t2.serving_status_cd not in ('EXCEPTION')    --confirm taken
	and dosage_form_t = 'INJECTION'   --confirm dosage form in INJECTION
	and route_adm_t != 'INTRAPERITONEAL'  --exclude INTRAPERITONEAL
	and tE.adm_dt between '2010-01-01' and '2010-12-31' -- test on only patients adm in 2010 
group by person_id,
	tE.encounter_id,
	adm_dt,
	disch_dt,
	drug_inpat_order_ingred_clean
order by person_id, encounter_id

/*Modify with Bel: Find all patients with pre drug ESRF(eGFR <= 15 or diag: ESRF)**/
--find first dose for each patient
select t.*,
	'N' as pre_flag_ESRF,
	'N' as pre_flag_eGFR15,
	'N' as flag_other_diag
--into  [Saphire_working].dbo.AKI_background
from  [Saphire_working].dbo.Amino_records_2010 t
order by person_id,encounter_id


/**Set all patient's flag_ESRF into 'Y' if it is showned in diagnosis table**/
--primary diag
Merge into  [Saphire_working].dbo.AKI_background T
Using (select substring(encounter_id, 
            charindex('_',encounter_id)+1, 
            (len(encounter_id) - charindex('_',REVERSE(encounter_id)) - charindex('_',encounter_id))) as person_id,
			min(encounter_id) as first_ESRF_diag_encounter
	  from t_primary_diagnosis 
	  where primary_diag_t like '%ESRF%'
			or primary_diag_t like '%ESRD%'
			or primary_diag_t like '%END STAGE RENAL DISEASE%'
			or primary_diag_t like '%END STAGE RENAL FAILURE%'
			or primary_diag_t like '%ENDSTAGE RENAL FAILURE%'
		or primary_diag_t like '%END-STAGE RENAL FAILURE%'
		group by substring(encounter_id, 
            charindex('_',encounter_id)+1, 
            (len(encounter_id) - charindex('_',REVERSE(encounter_id)) - charindex('_',encounter_id)))) as S
ON T.person_id = S.person_id
	and T.encounter_id > S.first_ESRF_diag_encounter --pre drug
WHEN MATCHED THEN
UPDATE SET pre_flag_ESRF = 'Y';

--Secondary diag
Merge into  [Saphire_working].dbo.AKI_background T
Using (select substring(encounter_id, 
            charindex('_',encounter_id)+1, 
            (len(encounter_id) - charindex('_',REVERSE(encounter_id)) - charindex('_',encounter_id))) as person_id,
			min(encounter_id) as first_ESRF_diag_encounter
	  from t_secondary_diagnosis 
	  where secondary_diag_t like '%ESRF%'
			or secondary_diag_t like '%ESRD%'
			or secondary_diag_t like '%END STAGE RENAL DISEASE%'
			or secondary_diag_t like '%END STAGE RENAL FAILURE%'
			or secondary_diag_t like '%ENDSTAGE RENAL FAILURE%'
		or secondary_diag_t like '%END-STAGE RENAL FAILURE%'
		group by substring(encounter_id, 
            charindex('_',encounter_id)+1, 
            (len(encounter_id) - charindex('_',REVERSE(encounter_id)) - charindex('_',encounter_id)))) as S
ON T.person_id = S.person_id
	and T.encounter_id > S.first_ESRF_diag_encounter --pre_drug
WHEN MATCHED THEN
UPDATE SET pre_flag_ESRF = 'Y';

/**Set all patient's flag_other_diag into 'Y' if it is showned in diagnosis table**/
--primary diag
Merge into  [Saphire_working].dbo.AKI_background T
Using (select encounter_id as other_diag_encounter
	  from t_primary_diagnosis 
	  where primary_diag_t COLLATE Latin1_General_CI_AS like '%antineopla%'
					or primary_diag_t COLLATE Latin1_General_CI_AS like '%cardiogenic shock%'
					or primary_diag_t COLLATE Latin1_General_CI_AS like '%hemorrhagic shock%'
					or primary_diag_t COLLATE Latin1_General_CI_AS like '%SEPTIC SHOCK%'
					or primary_diag_t COLLATE Latin1_General_CI_AS like '%TRAUMATIC SHOCK%'
					or primary_diag_t COLLATE Latin1_General_CI_AS like '%anaphylactic SHOCK%'
					or primary_diag_t  COLLATE Latin1_General_CI_AS like '%dialysis%' 
		) as S
ON  T.encounter_id = S.other_diag_encounter --pre drug
WHEN MATCHED THEN
UPDATE SET flag_other_diag = 'Y';

--Secondary diag
Merge into  [Saphire_working].dbo.AKI_background T
Using (select encounter_id as other_diag_encounter
	  from t_secondary_diagnosis 
	  where secondary_diag_t COLLATE Latin1_General_CI_AS like '%antineopla%'
					or secondary_diag_t COLLATE Latin1_General_CI_AS like '%cardiogenic shock%'
					or secondary_diag_t COLLATE Latin1_General_CI_AS like '%hemorrhagic shock%'
					or secondary_diag_t COLLATE Latin1_General_CI_AS like '%SEPTIC SHOCK%'
					or secondary_diag_t COLLATE Latin1_General_CI_AS like '%TRAUMATIC SHOCK%'
					or secondary_diag_t COLLATE Latin1_General_CI_AS like '%anaphylactic SHOCK%'
					or secondary_diag_t  COLLATE Latin1_General_CI_AS like '%dialysis%' 	
		) as S
ON T.encounter_id = S.other_diag_encounter --pre_drug
WHEN MATCHED THEN
UPDATE SET flag_other_diag = 'Y';


select * from [Saphire_working].dbo.AKI_background
------------------------------------------------------------------------------------------------------------------------------
/***Supplementary: Get other_diag details for these patients**/
select distinct t1.person_id, t1.encounter_id, t1.drug_inpat_order_ingred_clean, t2.primary_diag_t as diag_t
--into [Saphire_working].dbo.AKI_other_diag
from [Saphire_working].dbo.AKI_background t1 LEFT join  t_primary_diagnosis t2 on t1.encounter_id = t2.encounter_id
where  (primary_diag_t COLLATE Latin1_General_CI_AS like '%antineopla%'
					or primary_diag_t COLLATE Latin1_General_CI_AS like '%cardiogenic shock%'
					or primary_diag_t COLLATE Latin1_General_CI_AS like '%hemorrhagic shock%'
					or primary_diag_t COLLATE Latin1_General_CI_AS like '%SEPTIC SHOCK%'
					or primary_diag_t COLLATE Latin1_General_CI_AS like '%TRAUMATIC SHOCK%'
					or primary_diag_t COLLATE Latin1_General_CI_AS like '%anaphylactic SHOCK%'
					or primary_diag_t  COLLATE Latin1_General_CI_AS like '%dialysis%' 
		) 
UNION ALL	
select distinct t1.person_id, t1.encounter_id, t1.drug_inpat_order_ingred_clean, t2.secondary_diag_t as diag_t
from [Saphire_working].dbo.AKI_background t1 LEFT join t_secondary_diagnosis t2 on t1.encounter_id = t2.encounter_id
where	(secondary_diag_t COLLATE Latin1_General_CI_AS like '%antineopla%'
					or secondary_diag_t COLLATE Latin1_General_CI_AS like '%cardiogenic shock%'
					or secondary_diag_t COLLATE Latin1_General_CI_AS like '%hemorrhagic shock%'
					or secondary_diag_t COLLATE Latin1_General_CI_AS like '%SEPTIC SHOCK%'
					or secondary_diag_t COLLATE Latin1_General_CI_AS like '%TRAUMATIC SHOCK%'
					or secondary_diag_t COLLATE Latin1_General_CI_AS like '%anaphylactic SHOCK%'
					or secondary_diag_t  COLLATE Latin1_General_CI_AS like '%dialysis%' 
		)
order by person_id, encounter_id

select 
distinct person_id, encounter_id, drug_inpat_order_ingred_clean, diag_t
--into [Saphire_working].dbo.AKI_other_diag_2
from  [Saphire_working].dbo.AKI_other_diag


/****get the discharge summary for the 5 onset patients has other diagnosis***/
select *
from t_discharge_summary 
where encounter_id in ('20100111_2388928_NUH',
'20100506_5487610_NUH',
'20100601_5505941_NUH',
'20100808_5515986_NUH',
'20100913_5576451_NUH'
)


--------------------------------------------------------------------------------------------------------------------------------

/**Set all patient's pre_flag_eGFR15 into 'Y' if there is a eGFR < 15 before 1st dose_encounter**/
Merge into  [Saphire_working].dbo.AKI_background T
Using (select  t1.person_id,
			min(t1.specimen_received_dt) as first_eGFR15_dt
	  from t_lab_result t1
									LEFT JOIN t_demographics t2 on t1.person_id = t2.person_id 
								where t1.person_id in (
								select distinct person_id from [Saphire_working].dbo.AKI_background)
									and  [lab_test_specific_c] = 'CRE'
									and isnumeric(cast(lab_result as varchar))=1
									and CONVERT(INT,datediff(YEAR,birth_d,specimen_received_dt)) > 0 -- to get avoid of calcaulating issue
									and  175*POWER(CONVERT(INT, CONVERT(VARCHAR,lab_result))/88.4,-1.154)*power(1.00000*datediff(YEAR,birth_d,specimen_received_dt),-0.203) <
										CASE WHEN sex_cd = 'F' THEN 
											  15/0.742
													 ELSE
											  15
													 END
		group by t1.person_id) as S
ON T.person_id = S.person_id
	and T.drug_start_dt > S.first_eGFR15_dt
WHEN MATCHED THEN
UPDATE SET pre_flag_eGFR15 = 'Y';


--summary just for counting:
/****** Script for SelectTopNRows command from SSMS  ******/
SELECT  *
  FROM [Saphire_working].[dbo].AKI_background
/****End Modify:  [Saphire_working].dbo.ami_1st_dose is important table for pre drug renal funtion infor*****/


select drug_inpat_order_ingred_clean,
    pre_flag_ESRF,
	 pre_flag_eGFR15,
	flag_other_diag,
count( encounter_id) as encounter_cnt
from  [Saphire_working].dbo.AKI_background 
group by drug_inpat_order_ingred_clean,
pre_flag_ESRF,
	 pre_flag_eGFR15,
	flag_other_diag


/**Table 3**/
/****** Script for Select all AKI related lab test records  ******/
SELECT
      t_lab.[person_id]
      ,t_lab.[pat_type_cd]
	  ,t_lab.encounter_id
	  ,t2.adm_dt
	  ,t2.disch_dt
      ,[lab_category]
      ,[lab_code]
      ,[lab_name]
      ,[bodysite]
      ,[lab_test_specific_c]
      ,[lab_test_specific_t]
      ,[ref_range]
      ,[lab_result]
      ,[lab_result_indicator]
      ,[lab_unit]
      ,[flag_code]
	  ,order_d
      ,[specimen_collect_dt]
      ,[specimen_received_dt]  
into   [Saphire_working].[dbo].[lab_result_2010]      --Need to delete the table from server before re-run
  FROM [Saphire].[dbo].[t_lab_result] t_lab,
	[Saphire].dbo.t_encounter t2
  where t_lab.encounter_id = t2.encounter_id
	and t_lab.pat_type_cd = t2.pat_type_cd
	and [lab_test_specific_c] = 'CRE'
	and specimen_received_dt > adm_dt -- make sure all labs are done after adm -- added 6Apr2016
	and t2.person_id in (  --condition on the person is on aminoglycosides once
Select distinct tE.person_id
	From dbo.t_encounter tE,
	dbo.t_inpatient_med_order t1
		LEFT JOIN ct_common_dosage_form t3 on  t1.dosage_form_cd = t3.dosage_form_cd
	    LEFT JOIN [Saphire].dbo.ct_common_route_adm t4 on t1.route_adm_cd = t4.route_adm_cd,
	dbo.t_inpatient_med_serving t2
Where tE.encounter_id = t1.encounter_id
and tE.pat_type_cd = t1.pat_type_cd
and t1.encounter_id = t2.encounter_id  
and t1.order_id  = t2.order_id
and t1.drug_inpat_order_ingred_clean = t2.drug_inpat_serve_ingred_clean
and t1.drug_inpat_order_ingred_clean in ('AMIKACIN','GENTAMICIN','STREPTOMYCIN','NETILMICIN','KANAMYCIN')
	and t2.serving_status_cd not in ('EXCEPTION')    --confirm taken
	and dosage_form_t = 'INJECTION'   --confirm dosage form in INJECTION
	and route_adm_t != 'INTRAPERITONEAL'  --exclude INTRAPERITONEAL
	and tE.adm_dt between '2010-01-01' and '2010-12-31' -- test on only patients adm in 2010 
  )
 order by t_lab.person_id, t_lab.encounter_id

/***DTAT CLEANING***/ --to get rid off invalid form for lab result
 delete from  [Saphire_working].dbo.[lab_result_2010] 
-- Delete invalid lab_result result
where isnumeric(cast(lab_result as varchar)) !=1 

---change from here !!!!!!!!!!!!!!!!!!!!!!!!!!! As of 6Apr2016----------------------------------------------------

/***To get admSrCr****/

/**checking purpose**/ --LEFT side of the checking file in Excel
Select t2.encounter_id,
	   t2.adm_dt,
	   t2.drug_inpat_order_ingred_clean as drug_name,
	   t2.drug_start_dt,	 
	   lab_result,
	   specimen_received_dt
from [Saphire_working].dbo.[lab_result_2010] t1
		INNER JOIN [Saphire_working].dbo.Amino_records_2010 t2 on t1.encounter_id = t2.encounter_id --Keep those lab result that have inpat drug record
																						--encounter level, very encounter has unique admSrCr
	and specimen_received_dt < drug_start_dt 
	and specimen_received_dt >= t1.adm_dt   -- the lab_result should between adm and drug start date
order by t2.encounter_id

/**Aggregate to get the lowest lab_result as baseline admSrCr**/
Select t2.encounter_id,
	   t2.adm_dt,
	   t2.drug_inpat_order_ingred_clean as drug_name,
	   t2.drug_start_dt,	 
	   min(CONVERT(INT, CONVERT(VARCHAR,t1.lab_result))) as admSrCr
into [Saphire_working].dbo.admSrCr_table_2010   --Need to delete the table before re-run
from [Saphire_working].dbo.[lab_result_2010] t1
		INNER JOIN [Saphire_working].dbo.Amino_records_2010 t2 on t1.encounter_id = t2.encounter_id --Keep those lab result that have inpat drug record
																						--encounter level, very encounter has unique admSrCr
	and specimen_received_dt < drug_start_dt 
	and specimen_received_dt >= t1.adm_dt   -- the lab_result should between adm and drug start date
group by  t2.encounter_id,
	   t2.adm_dt,
	   t2.drug_inpat_order_ingred_clean ,
	   t2.drug_start_dt
order by encounter_id

/*Conti: just to add the lowest SrCr (baseline) occurence date**/
select adm.*,
		max(lab.specimen_received_dt) as SrCr_lowest_baseline_dt
into [Saphire_working].dbo.admSrCr_table2_2010
from [Saphire_working].dbo.admSrCr_table_2010 adm
		inner join (       --All lab_test within the adm and drug start dt..the same as CHECKING PURPOSE ONE
		Select t2.encounter_id,
	   t2.adm_dt,
	   t2.drug_start_dt,	 
	   lab_result,
	   specimen_received_dt
		from [Saphire_working].dbo.lab_result_2010 t1
			INNER JOIN [Saphire_working].dbo.Amino_records_2010 t2 on t1.encounter_id = t2.encounter_id --Keep those lab result that have inpat drug record
																						--encounter level, very encounter has unique admSrCr
		and specimen_received_dt < drug_start_dt 
		and specimen_received_dt >= t1.adm_dt   -- the lab_result should between adm and drug start date
		
		) lab  on adm.encounter_id = lab.encounter_id 
								and cast(adm.admSrCr as nvarchar(max)) = cast(lab.lab_result as nvarchar(max)) 
group by adm.encounter_id,
        drug_name ,
		adm.drug_start_dt,
		adm.adm_dt,
		adm.admSrCr
order by adm.encounter_id

/**To get pastSrCr***/
/**ckecking purpose**/  --LEFT side of the checking file in Excel
Select t2.person_id,
	   t2.encounter_id as encounter_drug, --the encounter_id according to the drug taken
	   t2.drug_inpat_order_ingred_clean as drug_name,
	   t2.drug_start_dt,
	   t1.encounter_id as encounter_lab,  --the encounter_id according to lab test taken
	   specimen_received_dt,
	   lab_result,
	   datediff(day,specimen_received_dt,drug_start_dt) as date_diff
from [Saphire_working].dbo.lab_result_2010 t1
		INNER JOIN [Saphire_working].dbo.Amino_records_2010 t2 on t1.person_id = t2.person_id --Keep those lab result that have inpat drug record																					--person level, very person & every 1year before drug_start_dt has unique pastSrCr
			and specimen_received_dt < drug_start_dt 
			and datediff(day,specimen_received_dt,drug_start_dt) < 365   -- the lab_result should between adm and drug start date
order by t2.person_id,t2.drug_inpat_order_ingred_clean, t2.drug_start_dt 


/**Aggregate to get the lowest lab_result as baseline pastSrCr**/
Select t2.person_id,
	   t2.drug_inpat_order_ingred_clean as drug_name,
	   t2.drug_start_dt,
	    min(CONVERT(INT, CONVERT(VARCHAR,t1.lab_result)))  pastSrCr
into [Saphire_working].dbo.pastSrCr_table_2010  --Need to delete the table before re-run
from [Saphire_working].dbo.lab_result_2010 t1
		INNER JOIN [Saphire_working].dbo.Amino_records_2010 t2 on t1.person_id = t2.person_id --Keep those lab result that have inpat drug record																					--person level, very person & every 1year before drug_start_dt has unique pastSrCr
			 and specimen_received_dt < drug_start_dt 
			 and datediff(day,specimen_received_dt,drug_start_dt) < 365   -- the lab_result should between adm and drug start date
group by t2.person_id,
		t2.drug_inpat_order_ingred_clean,
	t2.drug_start_dt    --drug_start_dt can decide which encounter is the drug taken
order by t2.person_id,drug_inpat_order_ingred_clean,drug_start_dt

/*Conti: just to add the lowest SrCr (baseline) occurence date**/
select past.*,
		max(lab.specimen_received_dt) as SrCr_lowest_baseline_dt  --Logic: if there are two lowest points, take the latest one before drug taken
--into [Saphire_working].dbo.pastSrCr_table2_2010
from [Saphire_working].dbo.pastSrCr_table_2010 past
		inner join (       --All lab_test within 1 year before drug taken dt..the same as CHECKING PURPOSE ONE
		Select t2.person_id,
		   t2.encounter_id as encounter_drug, --the encounter_id according to the drug taken
		   t2.drug_start_dt,
		   t1.encounter_id as encounter_lab,  --the encounter_id according to lab test taken
		   specimen_received_dt,
		  lab_result,
		   datediff(day,specimen_received_dt,drug_start_dt) as date_diff
		from [Saphire_working].dbo.lab_result_2010 t1
			INNER JOIN [Saphire_working].dbo.Amino_records_2010 t2 on t1.person_id = t2.person_id --Keep those lab result that have inpat drug record																					--person level, very person & every 1year before drug_start_dt has unique pastSrCr
				and specimen_received_dt < drug_start_dt 
				and datediff(day,specimen_received_dt,drug_start_dt) < 365   -- the lab_result should between adm and drug start date
		) lab  on past.person_id = lab.person_id 
										and cast(past.pastSrCr as nvarchar(max)) = cast(lab.lab_result as nvarchar(max)) 
group by past.person_id,
		past.drug_name,
		past.drug_start_dt,
		past.pastSrCr
order by past.person_id, drug_start_dt	



/**To get nadirSrCr***/

/**ckecking purpose**/
Select t2.person_id,
	   t2.encounter_id as encounter_drug, --the encounter_id according to the drug taken
	    t2.drug_inpat_order_ingred_clean as drug_name,
	   t2.drug_start_dt,
	   t1.encounter_id as encounter_lab,  --the encounter_id according to lab test taken
	   specimen_received_dt,
	   lab_result,
	   datediff(day,drug_start_dt,specimen_received_dt) as date_diff
from [Saphire_working].dbo.lab_result_2010 t1
		INNER JOIN [Saphire_working].dbo.Amino_records_2010 t2 on t1.person_id = t2.person_id --Keep those lab result that have inpat drug record																					--person level, very person & every 1year before drug_start_dt has unique pastSrCr
	         and specimen_received_dt > drug_start_dt    -- the lab_result should between adm and drug start date
order by t2.person_id, t2.drug_inpat_order_ingred_clean, t2.drug_start_dt


/**Aggregate to get the lowest lab_result as baseline nadirSrCr**/
Select t2.person_id,
      t2.drug_inpat_order_ingred_clean as drug_name,
	   t2.drug_start_dt,
	  min(CONVERT(INT, CONVERT(VARCHAR,t1.lab_result)))  nadirSrCr
into [Saphire_working].dbo.nadirSrCr_table_2010  --Need to delete the table before re-run
from [Saphire_working].dbo.lab_result_2010 t1
		INNER JOIN [Saphire_working].dbo.Amino_records_2010 t2 on t1.person_id = t2.person_id --Keep those lab result that have inpat drug record																					--person level, very person & every 1year before drug_start_dt has unique pastSrCr
			and specimen_received_dt > drug_start_dt    -- the lab_result should between adm and drug start date
group by t2.person_id,
		 t2.drug_inpat_order_ingred_clean,
		t2.drug_start_dt
order by t2.person_id ,
      t2.drug_start_dt

/*Conti: just to add the lowest SrCr (baseline) occurence date**/
select nadir.*,
		min(lab.specimen_received_dt) as SrCr_lowest_baseline_dt   -- if there are 2 lowest take the earliest one after taken drug
into [Saphire_working].dbo.nadirSrCr_table2_2010  --Need to delete the table before re-run
from [Saphire_working].dbo.nadirSrCr_table_2010 nadir
		inner join (       --All lab_test within 1 year before drug taken dt..the same as CHECKING PURPOSE ONE
			Select t2.person_id,
		   t2.encounter_id as encounter_drug, --the encounter_id according to the drug taken
		   t2.drug_start_dt,
		   t1.encounter_id as encounter_lab,  --the encounter_id according to lab test taken
		   specimen_received_dt,
		   lab_result,
		   datediff(day,drug_start_dt,specimen_received_dt) as date_diff
			from [Saphire_working].dbo.lab_result_2010 t1
			INNER JOIN [Saphire_working].dbo.Amino_records_2010 t2 on t1.person_id = t2.person_id --Keep those lab result that have inpat drug record																					--person level, very person & every 1year before drug_start_dt has unique pastSrCr
				  and specimen_received_dt > drug_start_dt    -- the lab_result should between adm and drug start date
		) lab  on nadir.person_id = lab.person_id 
										and cast(nadir.nadirSrCr as nvarchar(max)) = cast(lab.lab_result as nvarchar(max)) 
group by nadir.person_id,
		nadir.drug_name,
		nadir.drug_start_dt,
		nadir.nadirSrCr
order by nadir.person_id,
		nadir.drug_start_dt

/***Combine all adm, past, nadir baselines****/
/**** + to setup SrCr baseline**********/
select distinct t1.person_id,
		t1.encounter_id,
		t1.drug_inpat_order_ingred_clean,
		t1.adm_dt as adm_dt_with_drug,
		t1.drug_start_dt,
		t2.admSrCr,
		t2.SrCr_lowest_baseline_dt as admSrCr_dt, 
		t3.pastSrCr,
		t3.SrCr_lowest_baseline_dt as pastSrCr_dt, 
		t4.nadirSrCr,
		t4.SrCr_lowest_baseline_dt as nadirSrCr_dt, 
		t2.admSrCr as SrCr_baseline,  --baseline is admSrCr if admSrCr exist
		t2.SrCr_lowest_baseline_dt as SrCr_baseline_dt,
		'adm_SrCr' as SrCrbaseline_source
into [Saphire_working].dbo.SrCr_baseline_2010 
from  [Saphire_working].dbo.Amino_records_2010 t1
		LEFT JOIN  [Saphire_working].dbo.admSrCr_table2_2010 t2 on t1.encounter_id = t2.encounter_id and t1.drug_inpat_order_ingred_clean = t2.drug_name and t1.drug_start_dt = t2.drug_start_dt
		LEFT JOIN [Saphire_working].dbo.pastSrCr_table2_2010 t3 on t1.person_id = t3.person_id and t1.drug_inpat_order_ingred_clean = t3.drug_name and t1.drug_start_dt = t3.drug_start_dt
		LEFT JOIN [Saphire_working].dbo.nadirSrCr_table2_2010 t4 on t1.person_id = t4.person_id and t1.drug_inpat_order_ingred_clean = t4.drug_name and t1.drug_start_dt = t4.drug_start_dt
order by person_id, encounter_id

/**Need to run all these update according to correct sequency***/
update [Saphire_working].dbo.SrCr_baseline_2010 
set SrCr_baseline = pastSrCr,
  SrCr_baseline_dt = pastSrCr_dt,
	SrCrbaseline_source ='past' 
where SrCr_baseline is NULL   -- baseline is pastSrCr if admSrCr is null

update [Saphire_working].dbo.SrCr_baseline_2010 
set SrCr_baseline = nadirSrCr,
  SrCr_baseline_dt = nadirSrCr_dt,
   SrCrbaseline_source = 'nadir'
where SrCr_baseline is NULL  --baseline is nadirSrCr if both admSrCr and pastSrCr are null


update [Saphire_working].dbo.SrCr_baseline_2010 
set  SrCrbaseline_source = 'N.A'
where SrCr_baseline is NULL  --baseline source is N.A if baseline is still null

/**to export baseline as a result**/
select *
from [Saphire_working].dbo.SrCr_baseline_2010 


/***Make use of the picked SrCr baseline to determine whether each lab test is abnormal high*****/
/*Remark: abnormal high is > 1.5 *baseline**/

/*** 7days onset cases***/		
select t2.person_id,
		tB.drug_inpat_order_ingred_clean,
		t2.encounter_id as onset_encounter,
		t1.specimen_received_dt as prev_received_dt,
		t2.specimen_received_dt as second_received_dt,
		datediff(day,t1.specimen_received_dt,t2.specimen_received_dt) as onset_time_days,
		t2.specimen_received_dt as AKI_onset_dt,
		t1.lab_result as prev_lab_result,
		t2.lab_result as second_lab_result,
		CONVERT(INT, CONVERT(VARCHAR,t2.lab_result)) - CONVERT(INT, CONVERT(VARCHAR,t1.lab_result)) as SrCr_incr ,
		tB.SrCr_baseline,
		tB.SrCr_baseline_dt,
		tB.SrCrbaseline_source
into [Saphire_working].dbo.AKI_onset_7days_2010
from [Saphire_working].dbo.lab_result_2010 t1,
	 [Saphire_working].dbo.lab_result_2010 t2
		LEFT JOIN [Saphire_working].dbo.SrCr_baseline_2010 tB on t2.person_id = tB.person_id and t2.encounter_id = tB.encounter_id
where  t1.person_id = t2.person_id
	and CONVERT(INT, CONVERT(VARCHAR,t2.lab_result)) - CONVERT(INT, CONVERT(VARCHAR,t1.lab_result)) >CONVERT(INT, CONVERT(VARCHAR,SrCr_baseline)) *1.5  --increment is more than 1.5 baseline
	and  datediff(day,t1.specimen_received_dt,t2.specimen_received_dt) > 0
	and  datediff(day,t1.specimen_received_dt,t2.specimen_received_dt) < 7   --happen within 7 days

   
/***Table 4.2.2****/
/****To mapping onset information to drug history of each patient***/
/***7days cases***/
select t1.*
	    ,t2.AKI_onset_dt
		,t2.prev_lab_result
		,t2.prev_received_dt
		,t2.second_lab_result as scr_value_abnormal
		,t2.second_received_dt as scr_value_abnormal_dt
		,t2.SrCr_incr
		,datediff(day,t2.prev_received_dt,t2.second_received_dt) as duration_labs_days
		,datediff(day,t1.drug_start_dt,t2.second_received_dt) as latency_of_aki_days
		,t2.SrCr_baseline as scr_value_lowest
		,t2.SrCr_baseline_dt as scr_value_lowest_dt
		,t2.SrCrbaseline_source 
into [Saphire_working].dbo.AKI_onset_7days_2_2010
from [Saphire_working].dbo.Amino_records_2010 t1
		LEFT JOIN [Saphire_working].dbo.AKI_onset_7days_2010 t2 on t1.person_id = t2.person_id 
										and t1.drug_inpat_order_ingred_clean = t2.drug_inpat_order_ingred_clean
										and t1.encounter_id  = t2.onset_encounter --For every drugtaken, give that patient all 7day AKI signal
where t1.person_id = t2.person_id 	and datediff(day,t1.drug_start_dt,t2.second_received_dt) > 0   --check only if there is drug taken before lab
order by t1.person_id
		,t1.adm_dt

select count(distinct person_id) as pat_ct_7d
from [Saphire_working].dbo.AKI_onset_7days_2_2010

/*** 48hours onset cases***/	
/*Remark: abnormal when incr > 26.5 within 48hours**/
select t1.person_id,
		t2.encounter_id as onset_encounter,
        t1.specimen_received_dt as prev_received_dt,
		t2.specimen_received_dt as second_received_dt,
		datediff(hour,t1.specimen_received_dt,t2.specimen_received_dt) as onset_time_hours,
		t2.specimen_received_dt as AKI_onset_dt,
		t1.lab_result as prev_lab_result,
		t2.lab_result as second_lab_result,
		CONVERT(INT, CONVERT(VARCHAR,t2.lab_result)) - CONVERT(INT, CONVERT(VARCHAR,t1.lab_result)) as SrCr_incr  
into [Saphire_working].dbo.AKI_onset_48hours_2010
from [Saphire_working].dbo.lab_result_2010 t1,
     [Saphire_working].dbo.lab_result_2010 t2
where t1.person_id = t2.person_id  
	and CONVERT(INT, CONVERT(VARCHAR,t2.lab_result)) - CONVERT(INT, CONVERT(VARCHAR,t1.lab_result)) > 26.5 --increased more than 26.5
	and  datediff(hour,t1.specimen_received_dt,t2.specimen_received_dt) > 0
	and  datediff(hour,t1.specimen_received_dt,t2.specimen_received_dt) < 48    --happen within 48 hours



/***Table 4.2.2****/
/****To mapping onset information to drug history of each patient***/
/***48hours cases***/
select t1.*
	    ,t2.AKI_onset_dt
		,t2.prev_lab_result
		,t2.prev_received_dt
		,t2.second_lab_result as scr_value_abnormal
		,t2.second_received_dt as scr_value_abnormal_dt
		,t2.SrCr_incr
		,datediff(day,t2.prev_received_dt,t2.second_received_dt) as duration_labs_days
		,datediff(day,t1.drug_start_dt,t2.second_received_dt) as latency_of_aki_days
--into [Saphire_working].dbo.AKI_onset_48hours_2_2010
from [Saphire_working].dbo.Amino_records_2010 t1
		INNER JOIN [Saphire_working].dbo.AKI_onset_48hours_2010 t2 on t1.person_id = t2.person_id 
																	and t1.encounter_id = t2.onset_encounter --For every drugtaken, give that patient all 7day AKI signal
where t1.person_id = t2.person_id    --check only if there is drug taken before lab
order by t1.person_id
		,t1.adm_dt

select count(distinct person_id) as pat_ct_48h
from [Saphire_working].dbo.AKI_onset_48hours_2_2010

/* 12Apr2016 add flag indicate within 14days lactecy, and patient has onset pre_drug**/
select t1.*,
	CASE WHEN latency_of_aki_days > 0 and latency_of_aki_days <14
	THEN 'Y'
	ELSE 'N'
	END AS flag_within_14d,
	t2.flag_pre_drug_onset,
	t3.pre_flag_eGFR15, 
	t3.pre_flag_ESRF,
	t3.flag_other_diag
--into  [Saphire_working].dbo.AKI_onset_7days_3_2010
from [Saphire_working].dbo.AKI_onset_7days_2_2010 t1 LEFT join 
	(select distinct encounter_id, drug_inpat_order_ingred_clean, 'Y' as flag_pre_drug_onset from  [Saphire_working].dbo.AKI_onset_7days_2_2010 where latency_of_aki_days <0) t2
		on t1.encounter_id = t2.encounter_id and t1.drug_inpat_order_ingred_clean = t2.drug_inpat_order_ingred_clean
		inner join [Saphire_working].dbo.AKI_background t3 on t1.encounter_id = t3.encounter_id and t1.drug_inpat_order_ingred_clean = t3.drug_inpat_order_ingred_clean


/* 48h case */
select t1.*,
	CASE WHEN latency_of_aki_days > 0 and latency_of_aki_days <14
	THEN 'Y'
	ELSE 'N'
	END AS flag_within_14d,
	t2.flag_pre_drug_onset,
	t3.pre_flag_eGFR15, 
	t3.pre_flag_ESRF,
	t3.flag_other_diag
--into [Saphire_working].dbo.AKI_onset_48hours_3_2010
from [Saphire_working].dbo.AKI_onset_48hours_2_2010 t1 LEFT join 
	(select distinct encounter_id, drug_inpat_order_ingred_clean, 'Y' as flag_pre_drug_onset from  [Saphire_working].dbo.AKI_onset_48hours_2_2010 where latency_of_aki_days <0) t2
		on t1.encounter_id = t2.encounter_id and t1.drug_inpat_order_ingred_clean = t2.drug_inpat_order_ingred_clean
		inner join [Saphire_working].dbo.AKI_background t3 on t1.encounter_id = t3.encounter_id and t1.drug_inpat_order_ingred_clean = t3.drug_inpat_order_ingred_clean

/*Get the Statistics for onset patient**/
/*intersection*/
select distinct t1.encounter_id
from  [Saphire_working].dbo.AKI_onset_48hours_3_2010 t1 inner join 
	[Saphire_working].dbo.AKI_onset_7days_3_2010 t2 on t1.encounter_id = t2.encounter_id and  t1.drug_inpat_order_ingred_clean= t2.drug_inpat_order_ingred_clean
where t1.pre_flag_eGFR15 = 'N' and t1.pre_flag_ESRF ='N' and t1.flag_other_diag = 'N' and t1.flag_within_14d = 'Y'
	and t2.pre_flag_eGFR15 = 'N' and t2.pre_flag_ESRF ='N' and t2.flag_other_diag = 'N' and t2.flag_within_14d ='Y'

select distinct t1.encounter_id
from  [Saphire_working].dbo.AKI_onset_48hours_3_2010 t1 
where t1.pre_flag_eGFR15 = 'N' and t1.pre_flag_ESRF ='N' and t1.flag_other_diag = 'N' and t1.flag_within_14d = 'Y'

select distinct t1.encounter_id
from  [Saphire_working].dbo.AKI_onset_7days_3_2010 t1 
where t1.pre_flag_eGFR15 = 'N' and t1.pre_flag_ESRF ='N' and t1.flag_other_diag = 'N' and t1.flag_within_14d = 'Y'


/*Get all discharge summary**/
select substring(encounter_id, 
    charindex('_',encounter_id)+1, 
      (len(encounter_id) - charindex('_',REVERSE(encounter_id)) - charindex('_',encounter_id))) as person_id,*
into [Saphire_working].dbo.all_discharge_2010
from t_discharge_summary 
where (encounter_id in ( select encounter_id 
					from [Saphire_working].dbo.AKI_onset_48hours_3_2010
					where pre_flag_ESRF ='N' and pre_flag_eGFR15 = 'N' and flag_other_diag = 'N' and flag_within_14d ='Y'
					)
	or encounter_id in (select encounter_id 
					from [Saphire_working].dbo.AKI_onset_7days_3_2010
					where pre_flag_ESRF ='N' and pre_flag_eGFR15 = 'N' and flag_other_diag = 'N' and flag_within_14d ='Y'
					)
	)
order by substring(encounter_id, 
    charindex('_',encounter_id)+1, 
      (len(encounter_id) - charindex('_',REVERSE(encounter_id)) - charindex('_',encounter_id)))


SELECT * FROM [Saphire_working].dbo.all_discharge_2010


/*Try simple mining on discharge summary**/
select  substring(t1.encounter_id, 
    charindex('_',t1.encounter_id)+1, 
      (len(t1.encounter_id) - charindex('_',REVERSE(t1.encounter_id)) - charindex('_',t1.encounter_id))) as person_id,*
from  [Saphire_working].dbo.all_discharge_2010 t1 inner join t_primary_diagnosis t2 on t1.encounter_id = t2.encounter_id
where (hist_findings_t like '%amikacin%' COLLATE Latin1_General_CI_AS
		or hist_findings_t like '%gentamycin%' COLLATE Latin1_General_CI_AS
		or hist_findings_t like '%genta%' COLLATE Latin1_General_CI_AS
		or hist_findings_t like '%aminoglycoside%' COLLATE Latin1_General_CI_AS
		or hist_findings_t like '%nephrotoxic drug%'  COLLATE Latin1_General_CI_AS
		or hist_findings_t like '%polymyxin%' COLLATE Latin1_General_CI_AS
		or hist_findings_t like '%streptomycin%' COLLATE Latin1_General_CI_AS
		or hist_findings_t like '%kanamycin%' COLLATE Latin1_General_CI_AS
	)
	and (hist_findings_t like '%acute renal failure%' COLLATE Latin1_General_CI_AS
		or hist_findings_t like '%acute renal injury%' COLLATE Latin1_General_CI_AS
		or hist_findings_t like '%acute renal impairment%' COLLATE Latin1_General_CI_AS
		or hist_findings_t like '%acute kidney failure%' COLLATE Latin1_General_CI_AS
		or hist_findings_t like '%acute kidney injury%' COLLATE Latin1_General_CI_AS
		or hist_findings_t like '%acute kidney impairment%' COLLATE Latin1_General_CI_AS
		or hist_findings_t  COLLATE Latin1_General_CS_AS like '%[ ]AKI[ ]%'  
		or hist_findings_t  COLLATE Latin1_General_CS_AS  like '%[ ]ARF[ ]%' 
		or hist_findings_t like '%acute on chronic renal failure%'  COLLATE Latin1_General_CI_AS
		or hist_findings_t COLLATE Latin1_General_CI_AS like '%AoCKD%'  
		or hist_findings_t like '%nephrotoxicity%' COLLATE Latin1_General_CI_AS
		or hist_findings_t like '%acute on chronic renal impairment%' COLLATE Latin1_General_CI_AS
		or hist_findings_t like '%acute on chronic renal%' COLLATE Latin1_General_CI_AS
		or hist_findings_t like '%Acute glomerulonephritis%' COLLATE Latin1_General_CI_AS
		or hist_findings_t like '%Acute interstitial nephritis%' COLLATE Latin1_General_CI_AS
		or hist_findings_t like '%Acute tubular necrosis%' COLLATE Latin1_General_CI_AS
	)
--COMMENT NEXT LINE IF APPLY STRATEGY A , UNCOMMENT IF APPLY STRATEGY B	
-- and t1.encounter_id not in (select encounter_id from  [Saphire_working].dbo.AKI_onset_48hours_3_2010 where  flag_pre_drug_onset = 'Y' AND pre_flag_ESRF ='N' and pre_flag_eGFR15 = 'N' and flag_other_diag = 'N' and flag_within_14d ='Y')
order by substring(t1.encounter_id, 
    charindex('_',t1.encounter_id)+1, 
      (len(t1.encounter_id) - charindex('_',REVERSE(t1.encounter_id)) - charindex('_',t1.encounter_id)))


/******GET the result if only mining for Key word list*********************************/
select  substring(t1.encounter_id, 
    charindex('_',t1.encounter_id)+1, 
      (len(t1.encounter_id) - charindex('_',REVERSE(t1.encounter_id)) - charindex('_',t1.encounter_id))) as person_id,*
from t_discharge_summary t1
where (hist_findings_t like '%amikacin%' COLLATE Latin1_General_CI_AS
		or hist_findings_t like '%gentamycin%' COLLATE Latin1_General_CI_AS
		or hist_findings_t like '%genta%' COLLATE Latin1_General_CI_AS
		or hist_findings_t like '%aminoglycoside%' COLLATE Latin1_General_CI_AS
		or hist_findings_t like '%nephrotoxic drug%'  COLLATE Latin1_General_CI_AS
		or hist_findings_t like '%polymyxin%' COLLATE Latin1_General_CI_AS
		or hist_findings_t like '%streptomycin%' COLLATE Latin1_General_CI_AS
		or hist_findings_t like '%kanamycin%' COLLATE Latin1_General_CI_AS
	)
	and (hist_findings_t like '%acute renal failure%' COLLATE Latin1_General_CI_AS
		or hist_findings_t like '%acute renal injury%' COLLATE Latin1_General_CI_AS
		or hist_findings_t like '%acute renal impairment%' COLLATE Latin1_General_CI_AS
		or hist_findings_t like '%acute kidney failure%' COLLATE Latin1_General_CI_AS
		or hist_findings_t like '%acute kidney injury%' COLLATE Latin1_General_CI_AS
		or hist_findings_t like '%acute kidney impairment%' COLLATE Latin1_General_CI_AS
		or hist_findings_t  COLLATE Latin1_General_CS_AS like '%[ ]AKI[ ]%'  
		or hist_findings_t  COLLATE Latin1_General_CS_AS  like '%[ ]ARF[ ]%' 
		or hist_findings_t like '%acute on chronic renal failure%'  COLLATE Latin1_General_CI_AS
		or hist_findings_t COLLATE Latin1_General_CI_AS like '%AoCKD%'  
		or hist_findings_t like '%nephrotoxicity%' COLLATE Latin1_General_CI_AS
		or hist_findings_t like '%acute on chronic renal impairment%' COLLATE Latin1_General_CI_AS
		or hist_findings_t like '%acute on chronic renal%' COLLATE Latin1_General_CI_AS
		or hist_findings_t like '%Acute glomerulonephritis%' COLLATE Latin1_General_CI_AS
		or hist_findings_t like '%Acute interstitial nephritis%' COLLATE Latin1_General_CI_AS
		or hist_findings_t like '%Acute tubular necrosis%' COLLATE Latin1_General_CI_AS
	)
	and t1.encounter_id in(
	select distinct encounter_id from  [Saphire_working].dbo.Amino_records_2010 )



