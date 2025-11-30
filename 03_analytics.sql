-- =========================================================
-- 03_analytics.sql
--
-- Purpose:
--   This script builds the ANALYTICS layer on top of the
--   clean / relational model created in 02_clean_model.sql.
--
--   It does three main things:
--     1) Create an `analytics` schema (logical namespace).
--     2) Build aggregated summary tables (materialized).
--     3) Define views that are convenient for BI / exploration.
--
--   The goal is to answer questions like:
--     - Which skills are most in demand?
--     - Which industries post the most jobs?
--     - Which companies are most active?
--     - What do salary distributions look like per job title?
-- =========================================================



-- =======================
-- 0. SCHEMA ORGANIZATION
-- =======================
-- We keep all analytics objects in a dedicated schema
-- so they are clearly separated from raw and clean tables.

CREATE SCHEMA IF NOT EXISTS analytics;



-- ========================================================
-- A. MATERIALIZED SUMMARY TABLES
-- ========================================================
-- These are physical tables created from SELECT queries.
-- They store pre-aggregated results for faster analytics.
-- You can refresh them by re-running this script.
-- ========================================================



-- --------------------------------------------------------
-- A1. SKILL DEMAND
--
-- Question:
--   "Which skills are mentioned most often in job postings?"
--
-- Input tables:
--   - job_skills (link between job_id and skill_abr)
--   - skills (dimension: skill_abr -> skill_name)
--
-- Output:
--   analytics.skill_demand
--     - one row per skill_abr
--     - job_count = number of job postings requiring that skill
-- --------------------------------------------------------

DROP TABLE IF EXISTS analytics.skill_demand CASCADE;

CREATE TABLE analytics.skill_demand AS
SELECT
    js.skill_abr,
    sk.skill_name,
    COUNT(*) AS job_count
FROM job_skills js
LEFT JOIN skills sk
       ON sk.skill_abr = js.skill_abr
GROUP BY js.skill_abr, sk.skill_name
ORDER BY job_count DESC;



-- --------------------------------------------------------
-- A2. INDUSTRY DEMAND
--
-- Question:
--   "Which industries have the most job postings?"
--
-- Input tables:
--   - job_industries (link between job_id and industry_id)
--   - industries (dimension: industry_id -> industry_name)
--
-- Output:
--   analytics.industry_demand
--     - one row per industry_id
--     - job_count = number of job postings in that industry
-- --------------------------------------------------------

DROP TABLE IF EXISTS analytics.industry_demand CASCADE;

CREATE TABLE analytics.industry_demand AS
SELECT
    ji.industry_id,
    i.industry_name,
    COUNT(*) AS job_count
FROM job_industries ji
LEFT JOIN industries i
       ON i.industry_id = ji.industry_id
GROUP BY ji.industry_id, i.industry_name
ORDER BY job_count DESC;



-- --------------------------------------------------------
-- A3. COMPANY ACTIVITY
--
-- Question:
--   "Which companies are posting the most jobs?"
--
-- Input tables:
--   - companies (company dimension)
--   - jobs (fact table of job postings)
--
-- Output:
--   analytics.company_activity
--     - one row per company_id
--     - job_postings = count of job rows for that company
-- --------------------------------------------------------

DROP TABLE IF EXISTS analytics.company_activity CASCADE;

CREATE TABLE analytics.company_activity AS
SELECT
    c.company_id,
    c.company_name,
    COUNT(j.job_id) AS job_postings
FROM companies c
LEFT JOIN jobs j
       ON j.company_id = c.company_id
GROUP BY c.company_id, c.company_name
ORDER BY job_postings DESC;



-- --------------------------------------------------------
-- A4. ROW-LEVEL SALARY DATA (NORMALIZED)
--
-- Question:
--   "For each job posting that has salary info, what is the
--    min/med/max salary and an approximate annual salary?"
--
-- Idea:
--   - Keep one row per job_id with numeric salary columns.
--   - Compute an approximate annual pay:
--       HOURLY  -> med_salary * 40 * 52
--       MONTHLY -> med_salary * 12
--       else    -> assume med_salary is already annual.
--
-- Output:
--   analytics.salary_clean
--     - job_id, title, location, experience level
--     - min_salary / med_salary / max_salary (NUMERIC)
--     - annual_salary (NUMERIC, normalized)
--     - salary_range = max - min
-- --------------------------------------------------------

DROP TABLE IF EXISTS analytics.salary_clean CASCADE;

CREATE TABLE analytics.salary_clean AS
SELECT
    j.job_id,
    j.title,
    j.location,
    j.formatted_experience_level,
    s.pay_period,
    s.currency,
    s.compensation_type,

    -- These are already NUMERIC (or NULL) from 02_clean_model.sql
    s.min_salary,
    s.med_salary,
    s.max_salary,

    -- Approximate annual salary based on pay_period
    CASE
        WHEN s.med_salary IS NULL THEN NULL
        WHEN s.pay_period = 'HOURLY'  THEN s.med_salary * 40 * 52
        WHEN s.pay_period = 'MONTHLY' THEN s.med_salary * 12
        ELSE s.med_salary   -- assume already annual
    END AS annual_salary,

    -- Simple measure of spread
    (s.max_salary - s.min_salary) AS salary_range

FROM job_salaries s
JOIN jobs j
  ON j.job_id = s.job_id;


-- --------------------------------------------------------
-- A5. SALARY SUMMARY PER JOB TITLE
--
-- Question:
--   "For each job title, what do the salary distributions look like?"
--
-- Notes:
--   - Uses analytics.salary_clean (normalized salaries).
--   - Aggregates by title, computing average min/med/max and
--     average annual salary.
--
-- Output:
--   analytics.salary_summary
--     - one row per job title
--     - num_postings: number of salary records
--     - avg_min_salary / avg_med_salary / avg_max_salary
--     - avg_annual_salary
-- --------------------------------------------------------

DROP TABLE IF EXISTS analytics.salary_summary CASCADE;

CREATE TABLE analytics.salary_summary AS
SELECT
    title,
    COUNT(*) AS num_postings,
    AVG(min_salary)      AS avg_min_salary,
    AVG(med_salary)      AS avg_med_salary,
    AVG(max_salary)      AS avg_max_salary,
    AVG(annual_salary)   AS avg_annual_salary
FROM analytics.salary_clean
WHERE med_salary IS NOT NULL
GROUP BY title
ORDER BY avg_annual_salary DESC NULLS LAST;



-- ========================================================
-- B. ANALYTICAL VIEWS
-- ========================================================
-- Views are saved queries. They do not store data by
-- themselves (unlike the summary tables above).
-- They make it easier to query complex joins repeatedly.
-- ========================================================



-- --------------------------------------------------------
-- B1. JOB WITH SKILLS
-- --------------------------------------------------------

CREATE OR REPLACE VIEW analytics.v_job_with_skills AS
SELECT
    j.job_id,
    j.title,
    j.company_id,
    ARRAY_AGG(sk.skill_name ORDER BY sk.skill_name) AS skills
FROM jobs j
LEFT JOIN job_skills js
       ON js.job_id = j.job_id
LEFT JOIN skills sk
       ON sk.skill_abr = js.skill_abr
GROUP BY j.job_id, j.title, j.company_id;



-- --------------------------------------------------------
-- B2. JOB WITH INDUSTRIES
-- --------------------------------------------------------

CREATE OR REPLACE VIEW analytics.v_job_with_industries AS
SELECT
    j.job_id,
    j.title,
    ARRAY_AGG(i.industry_name ORDER BY i.industry_name) AS industries
FROM jobs j
LEFT JOIN job_industries ji
       ON ji.job_id = j.job_id
LEFT JOIN industries i
       ON i.industry_id = ji.industry_id
GROUP BY j.job_id, j.title;



-- --------------------------------------------------------
-- B3. JOB OVERVIEW (MAIN ANALYTICS VIEW)
-- --------------------------------------------------------

DROP VIEW IF EXISTS analytics.v_job_overview CASCADE;

CREATE VIEW analytics.v_job_overview AS
SELECT
    j.job_id,
    j.title,
    c.company_name,
    j.location,
    j.remote_allowed,
    -- skills array
    (
        SELECT v.skills
        FROM analytics.v_job_with_skills v
        WHERE v.job_id = j.job_id
    ) AS skills,
    -- industries array
    (
        SELECT v.industries
        FROM analytics.v_job_with_industries v
        WHERE v.job_id = j.job_id
    ) AS industries,
    sc.min_salary,
    sc.med_salary,
    sc.max_salary,
    sc.annual_salary,
    j.original_listed_time
FROM jobs j
LEFT JOIN companies c
       ON c.company_id = j.company_id
LEFT JOIN analytics.salary_clean sc
       ON sc.job_id = j.job_id;



-- ========================================================
-- C. EXAMPLE INSIGHT QUERIES (for manual use)
-- ========================================================
-- These are not creating objects; they are example SELECTs
-- that you can run manually in psql or any SQL client.
-- They also serve as documentation of what your model can
-- answer.
-- ========================================================


-- --------------------------------------------------------
-- C1. Top 15 most demanded skills
-- --------------------------------------------------------
-- SELECT * FROM analytics.skill_demand
-- ORDER BY job_count DESC
-- LIMIT 15;


-- --------------------------------------------------------
-- C2. Top 20 industries by job postings
-- --------------------------------------------------------
-- SELECT * FROM analytics.industry_demand
-- ORDER BY job_count DESC
-- LIMIT 20;


-- --------------------------------------------------------
-- C3. Top 20 highest-paying job titles (by avg annual salary)
-- --------------------------------------------------------
-- SELECT title, num_postings, avg_annual_salary
-- FROM analytics.salary_summary
-- WHERE avg_annual_salary IS NOT NULL
-- ORDER BY avg_annual_salary DESC
-- LIMIT 20;


-- --------------------------------------------------------
-- C4. Salary by experience level (using salary_clean)
-- --------------------------------------------------------
-- SELECT
--     formatted_experience_level AS experience,
--     COUNT(*)                 AS postings,
--     AVG(annual_salary)       AS avg_annual_salary
-- FROM analytics.salary_clean
-- GROUP BY formatted_experience_level
-- ORDER BY avg_annual_salary DESC NULLS LAST;


-- --------------------------------------------------------
-- C5. Top 20 most active companies by job postings
-- --------------------------------------------------------
-- SELECT company_name, job_postings
-- FROM analytics.company_activity
-- ORDER BY job_postings DESC
-- LIMIT 20;


-- --------------------------------------------------------
-- C6. Example of filtering the job overview view
-- --------------------------------------------------------
-- SELECT
--     title,
--     company_name,
--     location,
--     annual_salary,
--     remote_allowed,
--     skills
-- FROM analytics.v_job_overview
-- WHERE title ILIKE '%data engineer%'
-- ORDER BY annual_salary DESC NULLS LAST
-- LIMIT 20;
-- ========================================================
