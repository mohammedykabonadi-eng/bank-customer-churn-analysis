# Is the data loaded correctly?
select count(*) as total_number_of_customer
from bank_churn_clean;

select count(distinct CustomerId)
from bank_churn_clean;

-- 1. DATA QUALITY CHECKS (expect 10000 / 10000 / 0 / 0 / 0) Double check
select count(*) as total_rows,
       count(distinct CustomerId) as unique_customers,
        sum(case when Geography is null then 1 else 0 end) as null_geography,
        sum(case when EstimatedSalary is null then 1 else 0 end) as null_salary,
        sum(case when Exited not in (0,1) then 1 else 0 end) as bad_exited
from bank_churn_clean;

-- 2. BANDED VIEW (age, credit, balance, tenure groups)
create view customer_banded as
select c.*,
       case when age < 30 then '18-29'
            when age < 40 then '30-39'
            when age < 50 then '40-49'
            when age < 60 then '50-59'
            else '60+' end as age_group,
       case when CreditScore < 500 then 'Poor(<500)'
            when CreditScore < 600 then 'Fair(500-599)'
            when CreditScore < 700 then 'Good(600_699)'
            else 'Excellent (700+)' end as credit_band,
        case when Balance = 0 then 'Zero'
            when Balance < 100000 then 'Under 100k'
            when Balance < 150000 then '100k - 150k'
            else '150k+' end as balance_band,
        case when Tenure <= 2 then '0-2 years'
            when Tenure <= 5 then '3-5 years'
            when Tenure <= 8 then '6-8 years'
                else '9-10 years' end as tenure_group,
        case when IsActiveMember = 1 then 'Active'
            else 'Inactive' end as activity_status
from bank_churn_clean c;

-- 3. HEADLINE KPIs
select count(*) as total_customers,
       sum(Exited) as churned_customers,
        round(100 * sum(Exited) / count(*),1) as churn_rate_pct,
        round(100 * (count(*) - sum(Exited)) / count(*),1) as retention_rate_pct,
        round( avg(Balance),0) as avg_balance,
        round(sum(case  when Exited =1 then Balance else 0 end),0) as balance_lost,
        round(100 * sum(case  when Exited =1 then Balance else 0 end) / sum(Balance),1) as pct_balance_lost,
        round(100 * sum(IsActiveMember)/count(*),1) as active_rate_pct
from bank_churn_clean;

-- 4. CHURN BY EVERY DIMENSION + RANK WITHIN EACH DIMENSION

WITH seg AS (
    SELECT 'Country' AS dimension, Geography AS segment, Exited, Balance FROM customer_banded
    UNION ALL SELECT 'Gender',         Gender,                  Exited, Balance FROM customer_banded
    UNION ALL SELECT 'Age group',      age_group,               Exited, Balance FROM customer_banded
    UNION ALL SELECT 'Products',       CAST(NumOfProducts AS CHAR(5)), Exited, Balance FROM customer_banded
    UNION ALL SELECT 'Activity',       activity_status,         Exited, Balance FROM customer_banded
    UNION ALL SELECT 'Tenure',         tenure_group,            Exited, Balance FROM customer_banded
    UNION ALL SELECT 'Credit score',   credit_band,             Exited, Balance FROM customer_banded
    UNION ALL SELECT 'Balance band',   balance_band,            Exited, Balance FROM customer_banded
),
agg AS (
    SELECT dimension,
           segment,
           COUNT(*)                                                    AS customers,
           SUM(Exited)                                                 AS churned,
           ROUND(100.0 * SUM(Exited) / COUNT(*), 1)                    AS churn_rate_pct,
           ROUND(SUM(CASE WHEN Exited = 1 THEN Balance ELSE 0 END), 0) AS balance_lost
    FROM seg
    GROUP BY dimension, segment
)
SELECT dimension, segment, customers, churned, churn_rate_pct, balance_lost,
       RANK() OVER (PARTITION BY dimension ORDER BY churn_rate_pct DESC) AS risk_rank
FROM agg
ORDER BY dimension, risk_rank;

-- 5. INACTIVE vs ACTIVE: HOW MUCH MORE LIKELY TO LEAVE
with r as (
    select activity_status,100*sum(Exited)/count(*) as churn_rate
    from customer_banded
    group by activity_status
)
select round(max(case when activity_status = 'Inactive' then churn_rate end),1) as inactive_churn_pct,
       round(max(case when activity_status = 'Active' then churn_rate end),1) as active_churn_pct,
        round(max(case when activity_status = 'Inactive' then churn_rate end) / max(case when activity_status = 'Active' then churn_rate end),2) as relative_risk
from r;

-- 6. PROFILE OF HIGH-VALUE CUSTOMERS WHO CHURNED (balance 100K+, tenure 5+)
select Geography, age_group, count(*) as high_value_churned,
       round(sum(Balance)) as balance_lost,
       round(avg(NumOfProducts),1) as avg_products
from customer_banded
where Exited = 1 and Balance >= 100000 and Tenure >=5
group by Geography, age_group
order by balance_lost desc ;

-- 7. TOP 3 SEGMENTS TO TARGET (country x age group x activity)
--    Ranked by balance lost; assumes retention work cuts churn by 25%
with comb as (
    select Geography,age_group,activity_status,
           count(*) as customers,
           sum(Exited) as churned,
           round(100* sum(Exited) / count(*),1) as churn_rate_pct,
           round(sum(case when Exited = 1 then Balance else 0 end),0) as balance_lost
    from customer_banded
    group by Geography, age_group, activity_status
    having count(*) >= 100
),
ranked as (
    select comb.*,rank() over (order by balance_lost desc ) as priority_rank
    from comb
    where churn_rate_pct > 20
)
select priority_rank,Geography,age_group,activity_status,customers,churned,churn_rate_pct,balance_lost,
       round(balance_lost *0.25,0) as est_balance_saved_at_25pct
from ranked
where priority_rank <=3
order by priority_rank;
-- 8. HIGH-RISK CUSTOMER VIEW (customers still with the bank)
--    Risk score: 0-8 points, high risk = 5 or more

create view high_risk_customers as
select CustomerId,Surname,Geography,Gender,Age,age_group,Tenure,Balance,NumOfProducts,activity_status,risk_score
from (
    select b.*,
   (case when Age between 40 and 59 then 3 else 0 end)+
   (case when IsActiveMember = 0 then 2 else 0 end)+
   (case when Geography = 'Germany' then 1 else 0 end)+
   (case when NumOfProducts <> 2 then 1 else 0 end)+
   (case when Balance >= 100000 then 1 else 0 end ) as risk_score
   from customer_banded b
   where Exited = 0
     ) scored
where risk_score >=5;

select count(*) as high_risk_customers,
       round(sum(Balance),0) as balance_at_risk,
       round(AVG(Balance),0) as avg_balance
from high_risk_customers















