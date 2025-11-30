-- =========================================================
-- AUTO-GENERATED RAW TABLES + COPY COMMANDS
-- Root folder: C:\D\SQL\Linkedin_kaggle
-- One table per CSV file, all columns as TEXT.
-- =========================================================

-- ---------------------------------------------------------
-- 1. COMPANIES
-- Source CSV : data\companies\companies.csv
-- Table name : data_companies_companies_raw
-- ---------------------------------------------------------

DROP TABLE IF EXISTS data_companies_companies_raw CASCADE;

CREATE TABLE data_companies_companies_raw (
    company_id TEXT,
    name TEXT,
    description TEXT,
    company_size TEXT,
    state TEXT,
    country TEXT,
    city TEXT,
    zip_code TEXT,
    address TEXT,
    url TEXT
);

\COPY data_companies_companies_raw FROM 'C:/D/SQL/Linkedin_kaggle/data/companies/companies.csv' WITH (FORMAT csv, HEADER true);


-- ---------------------------------------------------------
-- 2. COMPANY INDUSTRIES
-- Source CSV : data\companies\company_industries.csv
-- Table name : data_companies_company_industries_raw
-- ---------------------------------------------------------

DROP TABLE IF EXISTS data_companies_company_industries_raw CASCADE;

CREATE TABLE data_companies_company_industries_raw (
    company_id TEXT,
    industry TEXT
);

\COPY data_companies_company_industries_raw FROM 'C:/D/SQL/Linkedin_kaggle/data/companies/company_industries.csv' WITH (FORMAT csv, HEADER true);


-- ---------------------------------------------------------
-- 3. COMPANY SPECIALITIES
-- Source CSV : data\companies\company_specialities.csv
-- Table name : data_companies_company_specialities_raw
-- ---------------------------------------------------------

DROP TABLE IF EXISTS data_companies_company_specialities_raw CASCADE;

CREATE TABLE data_companies_company_specialities_raw (
    company_id TEXT,
    speciality TEXT
);

\COPY data_companies_company_specialities_raw FROM 'C:/D/SQL/Linkedin_kaggle/data/companies/company_specialities.csv' WITH (FORMAT csv, HEADER true);


-- ---------------------------------------------------------
-- 4. EMPLOYEE COUNTS
-- Source CSV : data\companies\employee_counts.csv
-- Table name : data_companies_employee_counts_raw
-- ---------------------------------------------------------

DROP TABLE IF EXISTS data_companies_employee_counts_raw CASCADE;

CREATE TABLE data_companies_employee_counts_raw (
    company_id TEXT,
    employee_count TEXT,
    follower_count TEXT,
    time_recorded TEXT
);

\COPY data_companies_employee_counts_raw FROM 'C:/D/SQL/Linkedin_kaggle/data/companies/employee_counts.csv' WITH (FORMAT csv, HEADER true);


-- ---------------------------------------------------------
-- 5. JOB BENEFITS
-- Source CSV : data\jobs\benefits.csv
-- Table name : data_jobs_benefits_raw
-- ---------------------------------------------------------

DROP TABLE IF EXISTS data_jobs_benefits_raw CASCADE;

CREATE TABLE data_jobs_benefits_raw (
    job_id TEXT,
    inferred TEXT,
    type TEXT
);

\COPY data_jobs_benefits_raw FROM 'C:/D/SQL/Linkedin_kaggle/data/jobs/benefits.csv' WITH (FORMAT csv, HEADER true);


-- ---------------------------------------------------------
-- 6. JOB INDUSTRIES
-- Source CSV : data\jobs\job_industries.csv
-- Table name : data_jobs_job_industries_raw
-- ---------------------------------------------------------

DROP TABLE IF EXISTS data_jobs_job_industries_raw CASCADE;

CREATE TABLE data_jobs_job_industries_raw (
    job_id TEXT,
    industry_id TEXT
);

\COPY data_jobs_job_industries_raw FROM 'C:/D/SQL/Linkedin_kaggle/data/jobs/job_industries.csv' WITH (FORMAT csv, HEADER true);


-- ---------------------------------------------------------
-- 7. JOB SKILLS
-- Source CSV : data\jobs\job_skills.csv
-- Table name : data_jobs_job_skills_raw
-- ---------------------------------------------------------

DROP TABLE IF EXISTS data_jobs_job_skills_raw CASCADE;

CREATE TABLE data_jobs_job_skills_raw (
    job_id TEXT,
    skill_abr TEXT
);

\COPY data_jobs_job_skills_raw FROM 'C:/D/SQL/Linkedin_kaggle/data/jobs/job_skills.csv' WITH (FORMAT csv, HEADER true);


-- ---------------------------------------------------------
-- 8. JOB SALARIES
-- Source CSV : data\jobs\salaries.csv
-- Table name : data_jobs_salaries_raw
-- ---------------------------------------------------------

DROP TABLE IF EXISTS data_jobs_salaries_raw CASCADE;

CREATE TABLE data_jobs_salaries_raw (
    salary_id TEXT,
    job_id TEXT,
    max_salary TEXT,
    med_salary TEXT,
    min_salary TEXT,
    pay_period TEXT,
    currency TEXT,
    compensation_type TEXT
);

\COPY data_jobs_salaries_raw FROM 'C:/D/SQL/Linkedin_kaggle/data/jobs/salaries.csv' WITH (FORMAT csv, HEADER true);


-- ---------------------------------------------------------
-- 9. INDUSTRY MAPPINGS
-- Source CSV : data\mappings\industries.csv
-- Table name : data_mappings_industries_raw
-- ---------------------------------------------------------

DROP TABLE IF EXISTS data_mappings_industries_raw CASCADE;

CREATE TABLE data_mappings_industries_raw (
    industry_id TEXT,
    industry_name TEXT
);

\COPY data_mappings_industries_raw FROM 'C:/D/SQL/Linkedin_kaggle/data/mappings/industries.csv' WITH (FORMAT csv, HEADER true);


-- ---------------------------------------------------------
-- 10. SKILL MAPPINGS
-- Source CSV : data\mappings\skills.csv
-- Table name : data_mappings_skills_raw
-- ---------------------------------------------------------

DROP TABLE IF EXISTS data_mappings_skills_raw CASCADE;

CREATE TABLE data_mappings_skills_raw (
    skill_abr TEXT,
    skill_name TEXT
);

\COPY data_mappings_skills_raw FROM 'C:/D/SQL/Linkedin_kaggle/data/mappings/skills.csv' WITH (FORMAT csv, HEADER true);


-- ---------------------------------------------------------
-- 11. JOB POSTINGS
-- Source CSV : data\postings.csv
-- Table name : data_postings_raw
-- ---------------------------------------------------------

DROP TABLE IF EXISTS data_postings_raw CASCADE;

CREATE TABLE data_postings_raw (
    job_id TEXT,
    company_name TEXT,
    title TEXT,
    description TEXT,
    max_salary TEXT,
    pay_period TEXT,
    location TEXT,
    company_id TEXT,
    views TEXT,
    med_salary TEXT,
    min_salary TEXT,
    formatted_work_type TEXT,
    applies TEXT,
    original_listed_time TEXT,
    remote_allowed TEXT,
    job_posting_url TEXT,
    application_url TEXT,
    application_type TEXT,
    expiry TEXT,
    closed_time TEXT,
    formatted_experience_level TEXT,
    skills_desc TEXT,
    listed_time TEXT,
    posting_domain TEXT,
    sponsored TEXT,
    work_type TEXT,
    currency TEXT,
    compensation_type TEXT,
    normalized_salary TEXT,
    zip_code TEXT,
    fips TEXT
);

\COPY data_postings_raw FROM 'C:/D/SQL/Linkedin_kaggle/data/postings.csv' WITH (FORMAT csv, HEADER true);
