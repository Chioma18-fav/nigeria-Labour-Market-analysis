
-- Nigeria Labour Market Analytics
-- SQL Queries

-- This script documents the SQL workflow used to explore,
-- clean and prepare the NLFS dataset before statistical
-- analysis and Power BI dashboard development.


-- SECTION 1 - DATABASE EXPLORATION

SELECT table_name
FROM information_schema.tables
WHERE table_schema='public';

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name='staging_nlfs'
ORDER BY ordinal_position;

SELECT COUNT(*) AS total_rows
FROM staging_nlfs;

-- Structural missingness investigation
SELECT
    worked_last_7days,
    COUNT(*) AS total,
    SUM(CASE
            WHEN formal_job_registration IS NULL
              OR formal_job_registration=''
            THEN 1 ELSE 0
        END) AS missing_registration,
    ROUND(
        SUM(CASE
                WHEN formal_job_registration IS NULL
                  OR formal_job_registration=''
                THEN 1 ELSE 0
            END)*100.0/COUNT(*),1
    ) AS missing_pct
FROM clean_nlfs
GROUP BY worked_last_7days;

-- Confirm questionnaire flow
SELECT
    worked_last_7days,
    COUNT(*) AS total,
    COUNT(occupation_group) AS has_occupation,
    COUNT(industry_sector) AS has_industry,
    ROUND(COUNT(occupation_group)*100.0/COUNT(*),1) AS occupation_pct,
    ROUND(COUNT(industry_sector)*100.0/COUNT(*),1) AS industry_pct
FROM clean_nlfs
GROUP BY worked_last_7days
ORDER BY worked_last_7days;

-- SECTION 2 - DATA CLEANING & FEATURE ENGINEERING

DROP TABLE IF EXISTS clean_nlfs;

CREATE TABLE clean_nlfs AS
SELECT
    s.interview_key,
    s.id1_zone AS geopolitical_zone,
    s.id2_state AS state,
    s.id3_lga AS lga,
    s.id5_sector AS urban_rural,
    s.dc3 AS sex,
    s.dc5 AS age,
    s.dc6 AS marital_status,
    s.ed7 AS highest_education,

    -- Education rank derived column
    CASE TRIM(UPPER(COALESCE(s.ed7, 'NONE')))
        WHEN 'NONE' THEN 1
        WHEN 'FIRST SCHOOL LEAVING CERTIFICATE (FSLC)' THEN 2
        WHEN 'JUNIOR SECONDARY SCHOOL CERTIFICATE (JSS)' THEN 3
        WHEN 'NC/ND/NURSING' THEN 5
        WHEN 'ADVANCED (A) LEVEL' THEN 6
        WHEN 'VOC/COMM CERTIFICATE' THEN 6
        WHEN 'VOC/COMM DIPLOMA' THEN 6
        WHEN 'BA/BSC/HND' THEN 7
        WHEN 'MASTERS' THEN 8
        WHEN 'DOCTORATE' THEN 9
        ELSE 0
    END AS education_rank,

    s.atw1 AS worked_last_7days,
    s.mjj4 AS employment_type,
    s.mjj2ccleanmaingroup AS occupation_group,
    s.mjj3ccleansection AS industry_sector,
    s.mjj6 AS formal_job_registration,
    s.mjj8b_1 AS wage_payment,

    -- Formality classification derived column
    CASE 
        WHEN TRIM(UPPER(COALESCE(s.atw1,''))) = 'YES'
             AND TRIM(UPPER(COALESCE(s.mjj4,''))) = 'AS AN EMPLOYEE'
             AND TRIM(UPPER(COALESCE(s.mjj8b_1,''))) = 'YES'
        THEN 'Formal Employee'

        WHEN TRIM(UPPER(COALESCE(s.atw1,''))) = 'YES'
             AND TRIM(UPPER(COALESCE(s.mjj4,''))) = 'AS AN EMPLOYEE'
             AND TRIM(UPPER(COALESCE(s.mjj8b_1,''))) = 'NO'
        THEN 'Informal Employee'

        WHEN TRIM(UPPER(COALESCE(s.atw1,''))) = 'YES'
             AND TRIM(UPPER(COALESCE(s.mjj4,''))) = 'IN YOUR OWN BUSINESS/FARMING ACTIVITY'
             AND TRIM(UPPER(COALESCE(s.mjj6,''))) = 'YES'
        THEN 'Registered Self Employed'

        WHEN TRIM(UPPER(COALESCE(s.atw1,''))) = 'YES'
             AND TRIM(UPPER(COALESCE(s.mjj4,''))) = 'IN YOUR OWN BUSINESS/FARMING ACTIVITY'
             AND TRIM(UPPER(COALESCE(s.mjj6,''))) = 'NO'
        THEN 'Unregistered Self Employed'

        WHEN TRIM(UPPER(COALESCE(s.atw1,''))) = 'YES'
             AND TRIM(UPPER(COALESCE(s.mjj4,''))) IN (
                'AS AN APPRENTICE, INTERN',
                'HELPING IN A HOUSEHOLD BUSINESS',
                'HELPING A HOUSEHOLD MEMBER WHO WORKS FOR SOMEONE ELSE'
             )
        THEN 'Dependent Worker'

        WHEN TRIM(UPPER(COALESCE(s.atw1,''))) = 'NO'
             AND TRIM(UPPER(COALESCE(s.mjj4,''))) IN (
                'AS AN EMPLOYEE',
                'AS AN APPRENTICE, INTERN',
                'HELPING IN A HOUSEHOLD BUSINESS',
                'HELPING A HOUSEHOLD MEMBER WHO WORKS FOR SOMEONE ELSE'
             )
        THEN 'Employed - Temporarily Absent'

        WHEN TRIM(UPPER(COALESCE(s.atw1,''))) = 'NO'
             AND TRIM(UPPER(COALESCE(s.mjj4,''))) = 'IN YOUR OWN BUSINESS/FARMING ACTIVITY'
        THEN 'Casual Worker'

        WHEN TRIM(UPPER(COALESCE(s.atw1,''))) = 'NO'
             AND s.mjj4 IS NULL
        THEN 'Unemployed/Inactive'

        ELSE 'Other'
    END AS formality_category,

    s.popw AS survey_weight,
    s.quarter

FROM staging_nlfs s
WHERE s.dc5 >= 15;

-- SECTION 3 - VALIDATION

SELECT COUNT(*) FROM clean_nlfs;

SELECT column_name
FROM information_schema.columns
WHERE table_name='clean_nlfs'
ORDER BY ordinal_position;


-- SECTION 4 - BUSINESS ANALYSIS

-- Story 1: Education vs Occupation Tier
SELECT
highest_education,
education_rank,
CASE
WHEN LEFT(occupation_group,1) IN ('1','2','3') THEN 'High Skill'
WHEN LEFT(occupation_group,1) IN ('4','5','6','7','8') THEN 'Medium Skill'
WHEN LEFT(occupation_group,1)='9' THEN 'Low Skill'
ELSE 'Other'
END AS occupation_tier,
COUNT(*) AS total_workers
FROM clean_nlfs
WHERE worked_last_7days='YES'
GROUP BY highest_education, education_rank, occupation_tier
ORDER BY education_rank;

-- Story 2: Education vs Business Registration
SELECT
highest_education,
education_rank,
COUNT(*) total_businesses,
SUM(CASE WHEN formal_job_registration='YES' THEN 1 ELSE 0 END) registered,
ROUND(
SUM(CASE WHEN formal_job_registration='YES' THEN 1 ELSE 0 END)*100.0/COUNT(*),1
) registration_rate
FROM clean_nlfs
WHERE employment_type='In your own business/farming activity'
GROUP BY highest_education, education_rank
ORDER BY education_rank;

-- Story 3: Gender vs Occupation Tier
SELECT
sex,
CASE
WHEN LEFT(occupation_group,1) IN ('1','2','3') THEN 'High Skill'
WHEN LEFT(occupation_group,1) IN ('4','5','6','7','8') THEN 'Medium Skill'
WHEN LEFT(occupation_group,1)='9' THEN 'Low Skill'
END occupation_tier,
COUNT(*) total
FROM clean_nlfs
WHERE worked_last_7days='YES'
GROUP BY sex, occupation_tier;

-- Story 4: Region vs Occupation Tier
SELECT
geopolitical_zone,
CASE
WHEN LEFT(occupation_group,1) IN ('1','2','3') THEN 'High Skill'
WHEN LEFT(occupation_group,1) IN ('4','5','6','7','8') THEN 'Medium Skill'
WHEN LEFT(occupation_group,1)='9' THEN 'Low Skill'
END occupation_tier,
COUNT(*) total
FROM clean_nlfs
WHERE worked_last_7days='YES'
GROUP BY geopolitical_zone, occupation_tier;

-- Story 5: Age vs Occupation Tier
SELECT
CASE
WHEN age BETWEEN 15 AND 24 THEN '15-24'
WHEN age BETWEEN 25 AND 34 THEN '25-34'
WHEN age BETWEEN 35 AND 44 THEN '35-44'
WHEN age BETWEEN 45 AND 54 THEN '45-54'
ELSE '55+'
END age_group,
CASE
WHEN LEFT(occupation_group,1) IN ('1','2','3') THEN 'High Skill'
WHEN LEFT(occupation_group,1) IN ('4','5','6','7','8') THEN 'Medium Skill'
WHEN LEFT(occupation_group,1)='9' THEN 'Low Skill'
END occupation_tier,
COUNT(*) total
FROM clean_nlfs
WHERE worked_last_7days='YES'
GROUP BY age_group, occupation_tier;

-- Story 6: Labour Market Trend
SELECT
quarter,
CASE
WHEN formality_category IN ('Formal Employee','Registered Self Employed') THEN 'Formal'
WHEN formality_category IN ('Informal Employee','Unregistered Self Employed','Dependent Worker') THEN 'Informal'
WHEN formality_category IN ('Casual Worker','Employed - Temporarily Absent','Unemployed/Inactive') THEN 'Precarious'
END employment_category,
COUNT(*) total
FROM clean_nlfs
GROUP BY quarter, employment_category
ORDER BY quarter;
