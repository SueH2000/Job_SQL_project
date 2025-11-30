# Job_SQL_project
A small project in SQL and Tableau
# SQL Job Portal Analytics (LinkedIn Kaggle Dataset)

This side project explores job market patterns using PostgreSQL + Tableau on a LinkedIn job posting dataset.

## 1. Project Goals

- Load raw Kaggle CSVs into PostgreSQL.
- Build a clean relational model for:
  - companies, jobs, industries, skills, salaries
- Create an analytics layer to answer:
  - Which skills are most in demand?
  - Which industries and companies post the most jobs?
  - How do salaries vary by title and experience level?
- Visualize insights in Tableau.

## 2. Tech Stack

- PostgreSQL
- SQL (DDL + analytics queries)
- Python (for auto-generating raw table DDL)
- Tableau Public (dashboards)

## 3. Data

Original dataset from Kaggle: *LinkedIn Job Posting Dataset*  
Download CSVs and place them under `data/`.

## 4. SQL Pipeline

1. **Raw ingest** – `sql/01_create_and_load_raw.sql`  
   - Creates one `_raw` table per CSV.
   - Uses `\COPY` to load LinkedIn Kaggle files.

2. **Clean model** – `sql/02_clean_model.sql`  
   - Normalizes:
     - `companies`, `industries`, `skills`
     - `jobs`, `job_skills`, `job_industries`, `job_benefits`, `job_salaries`
   - Converts salary fields to numeric.
   - Adds indexes and simple constraints.

3. **Analytics layer** – `sql/03_analytics.sql`  
   - Creates `analytics` schema.
   - Materialized summary tables:
     - `analytics.skill_demand`
     - `analytics.industry_demand`
     - `analytics.company_activity`
     - `analytics.salary_summary`
   - Views:
     - `analytics.v_job_with_skills`
     - `analytics.v_job_with_industries`
     - `analytics.v_job_overview`

## 5. Tableau Dashboards

Tableau workbook: `tableau/job_portal_analysis.twbx`


## 6. How to Run Locally

1. Create PostgreSQL database `job_portal`.
2. Run:

```sql
\i sql/01_create_and_load_raw.sql
\i sql/02_clean_model.sql
\i sql/03_analytics.sql
