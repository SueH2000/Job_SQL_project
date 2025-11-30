-- =========================================================
-- 02_clean_model.sql
-- Build a clean, analysis-ready schema on top of *_raw tables.
--
-- Raw layer:
--   - data_companies_*_raw
--   - data_jobs_*_raw
--   - data_mappings_*_raw
--   - data_postings_raw
--
-- Clean/model layer (created here):
--   - industries
--   - skills
--   - companies
--   - jobs
--   - job_industries
--   - job_skills
--   - job_benefits
--   - job_salaries
--
-- Design:
--   - Raw stays unchanged (staging).
--   - Clean tables are typed, joined, and indexed for analysis.
-- =========================================================


-- =======================
-- 1. DIMENSIONS
-- =======================

-- 1.1 Industries: one row per industry_id
DROP TABLE IF EXISTS industries CASCADE;
CREATE TABLE industries (
    industry_id   TEXT PRIMARY KEY,
    industry_name TEXT
);

INSERT INTO industries (industry_id, industry_name)
SELECT DISTINCT
    industry_id,
    industry_name
FROM data_mappings_industries_raw
WHERE industry_id IS NOT NULL;

-- 1.2 Skills: one row per skill_abr
DROP TABLE IF EXISTS skills CASCADE;
CREATE TABLE skills (
    skill_abr   TEXT PRIMARY KEY,
    skill_name  TEXT
);

INSERT INTO skills (skill_abr, skill_name)
SELECT DISTINCT
    skill_abr,
    skill_name
FROM data_mappings_skills_raw
WHERE skill_abr IS NOT NULL;



-- =======================
-- 2. COMPANIES
-- =======================

-- Goal:
--   - One row per company_id.
--   - Basic info from data_companies_companies_raw.
--   - Latest employee_count & follower_count from data_companies_employee_counts_raw.
--
-- Note:
--   time_recorded is TEXT in raw; we just use it to pick the "latest" by max().

DROP TABLE IF EXISTS companies CASCADE;

CREATE TABLE companies AS
WITH companies_clean AS (
    SELECT
        CASE
            -- company_id contains only digits and dots (e.g. '2774458', '2774458.0')
            WHEN company_id ~ '^[0-9.]+$'
                THEN (company_id::NUMERIC::BIGINT)::TEXT  -- normalize: 2774458.0 -> 2774458
            ELSE company_id
        END AS company_id,
        name,
        description,
        company_size,
        state,
        country,
        city,
        zip_code,
        address,
        url
    FROM data_companies_companies_raw
    WHERE company_id IS NOT NULL
)
SELECT
    company_id,
    MIN(name)        AS company_name,
    MIN(description) AS description,
    MIN(company_size) AS company_size,
    MIN(state)       AS state,
    MIN(country)     AS country,
    MIN(city)        AS city,
    MIN(zip_code)    AS zip_code,
    MIN(address)     AS address,
    MIN(url)         AS url
FROM companies_clean
GROUP BY company_id;

ALTER TABLE companies
    ADD CONSTRAINT pk_companies PRIMARY KEY (company_id);

CREATE INDEX idx_companies_country_city
    ON companies(country, city);


-- =======================
-- 3. JOBS (POSTINGS)
-- =======================

-- Goal:
--   - One row per job_id.
--   - Structure the core job attributes.
--   - Keep date/time fields as TEXT for now (format can be inspected later).
--   - Convert normalized_salary to NUMERIC when possible.
DROP TABLE IF EXISTS jobs CASCADE;

CREATE TABLE jobs AS
WITH postings_clean AS (
    SELECT
        p.job_id,
        CASE
            WHEN p.company_id ~ '^[0-9.]+$'
                THEN (p.company_id::NUMERIC::BIGINT)::TEXT
            ELSE p.company_id
        END AS company_id_clean,
        p.company_name,
        p.title,
        p.description,
        p.location,
        p.formatted_work_type,
        p.work_type,
        p.formatted_experience_level,
        p.listed_time,
        p.original_listed_time,
        p.remote_allowed,
        NULLIF(p.views, '')::NUMERIC   AS views,
        NULLIF(p.applies, '')::NUMERIC AS applies,
        p.posting_domain,
        p.currency,
        p.compensation_type,
        NULLIF(p.max_salary, '')::NUMERIC        AS max_salary_raw,
        NULLIF(p.med_salary, '')::NUMERIC        AS med_salary_raw,
        NULLIF(p.min_salary, '')::NUMERIC        AS min_salary_raw,
        NULLIF(p.normalized_salary, '')::NUMERIC AS normalized_salary,
        p.zip_code,
        p.fips
    FROM data_postings_raw p
    WHERE p.job_id IS NOT NULL
),
jobs_src AS (
    SELECT
        p.job_id,
        p.company_id_clean AS company_id,
        p.company_name,
        p.title,
        p.description,
        p.location,
        p.formatted_work_type,
        p.work_type,
        p.formatted_experience_level,
        p.listed_time,
        p.original_listed_time,
        p.remote_allowed,
        p.views,
        p.applies,
        p.posting_domain,
        p.currency,
        p.compensation_type,
        p.max_salary_raw,
        p.med_salary_raw,
        p.min_salary_raw,
        p.normalized_salary,
        p.zip_code,
        p.fips
    FROM postings_clean p
    JOIN companies c
      ON p.company_id_clean = c.company_id   -- now using normalized IDs
)
SELECT * FROM jobs_src;

ALTER TABLE jobs
    ADD CONSTRAINT pk_jobs PRIMARY KEY (job_id);

ALTER TABLE jobs
    ADD CONSTRAINT fk_jobs_company
    FOREIGN KEY (company_id) REFERENCES companies(company_id);

CREATE INDEX idx_jobs_company_id ON jobs(company_id);
CREATE INDEX idx_jobs_title      ON jobs(title);
CREATE INDEX idx_jobs_location   ON jobs(location);
CREATE INDEX idx_jobs_remote     ON jobs(remote_allowed);


-- =======================
-- 4. RELATION TABLES (LINKS)
-- =======================

-- 4.1 Job ↔ Industries
DROP TABLE IF EXISTS job_industries CASCADE;

CREATE TABLE job_industries AS
SELECT DISTINCT
    ji.job_id,
    ji.industry_id
FROM data_jobs_job_industries_raw ji
JOIN jobs j
  ON ji.job_id = j.job_id          -- keep only job_ids that exist in jobs
JOIN industries i
  ON ji.industry_id = i.industry_id;  -- keep only industry_ids that exist in industries

ALTER TABLE job_industries
    ADD CONSTRAINT fk_job_industries_job
    FOREIGN KEY (job_id) REFERENCES jobs(job_id);

ALTER TABLE job_industries
    ADD CONSTRAINT fk_job_industries_industry
    FOREIGN KEY (industry_id) REFERENCES industries(industry_id);

CREATE INDEX idx_job_industries_job      ON job_industries(job_id);
CREATE INDEX idx_job_industries_industry ON job_industries(industry_id);


-- 4.2 Job ↔ Skills
DROP TABLE IF EXISTS job_skills CASCADE;

CREATE TABLE job_skills AS
SELECT DISTINCT
    js.job_id,
    js.skill_abr
FROM data_jobs_job_skills_raw js
JOIN jobs j
  ON js.job_id = j.job_id           -- keep only job_ids that exist in jobs
JOIN skills s
  ON js.skill_abr = s.skill_abr;    -- keep only skill_abrs that exist in skills

ALTER TABLE job_skills
    ADD CONSTRAINT fk_job_skills_job
    FOREIGN KEY (job_id) REFERENCES jobs(job_id);

ALTER TABLE job_skills
    ADD CONSTRAINT fk_job_skills_skill
    FOREIGN KEY (skill_abr) REFERENCES skills(skill_abr);

CREATE INDEX idx_job_skills_job   ON job_skills(job_id);
CREATE INDEX idx_job_skills_skill ON job_skills(skill_abr);


-- 4.3 Job ↔ Benefits
DROP TABLE IF EXISTS job_benefits CASCADE;

CREATE TABLE job_benefits AS
SELECT DISTINCT
    b.job_id,
    b.inferred,
    b.type
FROM data_jobs_benefits_raw b
JOIN jobs j
  ON b.job_id = j.job_id;           -- keep only job_ids that exist in jobs

ALTER TABLE job_benefits
    ADD CONSTRAINT fk_job_benefits_job
    FOREIGN KEY (job_id) REFERENCES jobs(job_id);

CREATE INDEX idx_job_benefits_job ON job_benefits(job_id);



-- =======================
-- 5. SALARIES (TYPED)
-- =======================

-- Goal:
--   - Convert salary fields from TEXT to NUMERIC.
--   - Keep pay_period, currency, compensation_type as categorical TEXT.
--   - Keep only rows whose job_id exists in jobs (so FK is valid).

DROP TABLE IF EXISTS job_salaries CASCADE;

CREATE TABLE job_salaries AS
SELECT
    s.salary_id,
    s.job_id,
    NULLIF(s.max_salary, '')::NUMERIC AS max_salary,
    NULLIF(s.med_salary, '')::NUMERIC AS med_salary,
    NULLIF(s.min_salary, '')::NUMERIC AS min_salary,
    s.pay_period,
    s.currency,
    s.compensation_type
FROM data_jobs_salaries_raw s
JOIN jobs j
  ON s.job_id = j.job_id;           -- keep only job_ids that exist in jobs

ALTER TABLE job_salaries
    ADD CONSTRAINT pk_job_salaries PRIMARY KEY (salary_id);

ALTER TABLE job_salaries
    ADD CONSTRAINT fk_job_salaries_job
    FOREIGN KEY (job_id) REFERENCES jobs(job_id);

CREATE INDEX idx_job_salaries_job ON job_salaries(job_id);
