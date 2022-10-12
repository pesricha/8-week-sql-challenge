----------------------------
------(A) USER JOURNEY------
----------------------------
SELECT 
	s.customer_id,
    s.plan_id,
    pl.plan_name,
    s.start_date
FROM foodie_fi.subscriptions s
JOIN foodie_fi.plans pl
ON pl.plan_id = s.plan_id
WHERE customer_id in (23,89) -- List of ids under consideration
ORDER BY 1,4
/* Since this is a case study, we are taking in two examples for customer_id 23 and 89
The above query outputs to-:

| customer_id | plan_id | plan_name   | start_date               |
| ----------- | ------- | ----------- | ------------------------ |
| 23          | 0       | trial       | 2020-05-13T00:00:00.000Z |
| 23          | 3       | pro annual  | 2020-05-20T00:00:00.000Z |
| 89          | 0       | trial       | 2020-03-05T00:00:00.000Z |
| 89          | 2       | pro monthly | 2020-03-12T00:00:00.000Z |
| 89          | 4       | churn       | 2020-09-02T00:00:00.000Z |

---
/* INFERENCES
#1) CUSTOMER 23 starts with a trial on 2020-05-13 and upgrades 
    it to a pro annual plan after 7 days on 2020-05-20
#2) CUSTOMER 89 starts with a trial on 2020-03-05, upgrades it 
    to a pro monthly(that happens by default) on 2020-03-12 and
    decides to leave the service on 2020-09-02, which comes into
    effect on 2020-09-12 (the previous billing period).
*/

---------------------------------------
------(B) DATA ANALYSIS QUESTIONS------
---------------------------------------


--  #1)    How many customers has Foodie-Fi ever had?
            SELECT COUNT(DISTINCT customer_id)
            FROM foodie_fi.subscriptions;

--  #2)    What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
            SELECT 
                date_part('month',  start_date) as month_,
                COUNT(start_date) as trial_start
            FROM foodie_fi.subscriptions
            WHERE plan_id = 0
            GROUP BY 1

--  #3)    What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
            SELECT 
              pl.plan_name,
                COUNT(pl.plan_name)
            FROM foodie_fi.subscriptions s
            JOIN foodie_fi.plans pl
            ON pl.plan_id = s.plan_id
            WHERE s.start_date > '2020-12-31'
            GROUP BY 1

--  #4)    What is the customer count and percentage of customers who have churned rounded to 1 decimal ``place?
            SELECT 
              COUNT(*) AS churn_count,
              ROUND(100 * COUNT(*)::NUMERIC / (
                SELECT COUNT(DISTINCT customer_id) 
                FROM foodie_fi.subscriptions),1) AS churn_percentage
            FROM foodie_fi.subscriptions s
            JOIN foodie_fi.plans p
              ON s.plan_id = p.plan_id
            WHERE s.plan_id = 4;

--  #5)    How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
            WITH t1 as (SELECT 
              * ,
                DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY start_date) as ranking
            FROM foodie_fi.subscriptions s)

            SELECT 
              COUNT(t1.*),
                ROUND(100*1.0*(SELECT COUNT(*) FROM t1 WHERE t1.ranking= 2 and t1.plan_id =4)/(SELECT COUNT(DISTINCT s.customer_id) FROM foodie_fi.subscriptions s),0) as perc 
            FROM t1 
            WHERE t1.plan_id = 4 and t1.ranking =2

--  #6)    What is the number and percentage of customer plans after their initial free trial?
            With t1 as (
            SELECT 
              customer_id,
              plan_id,
              LEAD(plan_id,1) OVER(PARTITION BY customer_id ORDER BY plan_id) as next_plan
            FROM foodie_fi.subscriptions 
            )
            ,
            t2 as (SELECT next_plan,
              COUNT(*) as next_plan_count
            FROM t1
            WHERE plan_id = 0
            GROUP BY next_plan)

            SELECT t2.*,
                ROUND(100.0*(t2.next_plan_count) / (SELECT COUNT(DISTINCT customer_id) FROM foodie_fi.subscriptions),1) as perc
            FROM t2
    
--  #7)    What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?

--  #8)    How many customers have upgraded to an annual plan in 2020?
            SELECT COUNT(DISTINCT customer_id)
            FROM foodie_fi.subscriptions s
            WHERE start_date <= '2020-12-31' and plan_id = 3

--  #9)    How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
            WITH trial_plan AS 
            (SELECT 
              customer_id, 
              start_date AS trial_date
            FROM foodie_fi.subscriptions
            WHERE plan_id = 0
            ),

            annual_plan AS
            (SELECT 
              customer_id, 
              start_date AS annual_date
            FROM foodie_fi.subscriptions
            WHERE plan_id = 3
            )

            SELECT 
                    ROUND(AVG(annual_date-trial_date),0 )as avg_day_diff
            FROM trial_plan tp
            JOIN annual_plan ap
            ON ap.customer_id = tp.customer_id

--  #10)   Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
            WITH trial_plan AS 
            (SELECT 
              customer_id, 
              start_date AS trial_date
            FROM foodie_fi.subscriptions
            WHERE plan_id = 0
            ),

            annual_plan AS
            (SELECT 
              customer_id, 
              start_date AS annual_date
            FROM foodie_fi.subscriptions
            WHERE plan_id = 3
            ),

            t3 as (SELECT ap.* ,
                tp.*,
                    (((annual_date-trial_date)/30))*30 + 1 || '-' ||
                    (((annual_date-trial_date)/30)+1)*30 as period_
            FROM trial_plan tp
            JOIN annual_plan ap
            ON tp.customer_id = ap.customer_id)

            SELECT 
              period_,
                count(period_)
            FROM t3 
            GROUP BY 1


--  #11)   How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
          WITH t1 as
          (
          SELECT customer_id,
            plan_id,
            start_date,
            LEAD(plan_id,1) OVER (PARTITION BY customer_id ORDER BY start_date ) as next_plan
          FROM foodie_fi.subscriptions 
          )

          SELECT COUNT(DISTINCT customer_id) 
          FROM t1
          WHERE next_plan = 1 and plan_id = 2
