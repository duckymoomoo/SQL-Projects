-- Link to case study https://8weeksqlchallenge.com/case-study-3/
SELECT *
FROM plans;

SELECT *
FROM subscriptions;

-- How many customers has Foodie-Fi ever had?
SELECT COUNT(DISTINCT customer_id)
FROM subscriptions;
# There are a total of 1000 customers

-- What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
SELECT SUBSTRING(sub.start_date,6,2) AS months, COUNT(*)
FROM subscriptions AS sub
JOIN plans
	ON sub.plan_id = plans.plan_id
WHERE plans.plan_name = 'trial'
GROUP BY months
ORDER BY months;

-- What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
SELECT plans.plan_name
FROM plans
JOIN subscriptions AS sub
	ON plans.plan_id = sub.plan_id
WHERE sub.start_date > '2020-12-31';

SELECT plans.plan_name, COUNT(plans.plan_name)
FROM plans
JOIN subscriptions AS sub
	ON plans.plan_id = sub.plan_id
WHERE sub.start_date > '2020-12-31'
GROUP BY plans.plan_name;

-- What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
SELECT DISTINCT customer_id
FROM subscriptions
WHERE plan_id = '4';

WITH churned_customers AS
(SELECT DISTINCT customer_id
FROM subscriptions
WHERE plan_id = '4'
)
SELECT COUNT(*)
FROM churned_customers;

SELECT COUNT(DISTINCT customer_id)
FROM subscriptions;

WITH churned_counts AS
(WITH churned_customers AS
(SELECT DISTINCT customer_id
FROM subscriptions
WHERE plan_id = '4'
)
SELECT COUNT(*) AS churned_count
FROM churned_customers
),
total_counts AS
(SELECT COUNT(DISTINCT customer_id) AS total_count
FROM subscriptions
)
SELECT churned_count, ROUND((churned_count / total_count) * 100, 1) 
FROM churned_counts, total_counts
;
# 307 churned customers, 30.7%

-- How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
#trial customers
SELECT customer_id
FROM subscriptions
WHERE plan_id = 0;

#churned customers
SELECT DISTINCT customer_id
FROM subscriptions
WHERE plan_id = '4';

SELECT MAX(start_date)
FROM subscriptions
WHERE plan_id = 0;

#customers after trial
WITH trial_customers AS
(SELECT customer_id
FROM subscriptions
WHERE plan_id = 0
),
churned_customers AS
(SELECT DISTINCT customer_id
FROM subscriptions
WHERE plan_id = '4'
)
SELECT t.customer_id
FROM trial_customers AS t
JOIN subscriptions AS s
	ON t.customer_id = s.customer_id
WHERE s.start_date > (SELECT MAX(start_date)
					FROM subscriptions AS sub
					WHERE sub.customer_id = t.customer_id
                    AND plan_id = 0)
	AND s.plan_id = 4;

WITH trial_customers AS
(SELECT customer_id
FROM subscriptions
WHERE plan_id = 0
),
churned_customers AS
(SELECT DISTINCT customer_id
FROM subscriptions
WHERE plan_id = '4'
),
customers_after_trial AS
(SELECT t.customer_id
FROM trial_customers AS t
JOIN subscriptions AS s
	ON t.customer_id = s.customer_id
WHERE s.start_date > (SELECT sub.start_date
					FROM subscriptions AS sub
					WHERE sub.customer_id = t.customer_id
                    AND plan_id = 0)
	AND s.plan_id = 4
),
total_trial_customers AS
(SELECT COUNT(DISTINCT customer_id) AS total_trial_count
FROM trial_customers
),
churned_after_trial AS
(SELECT COUNT(DISTINCT customer_id) AS churned_after_trial_count
FROM customers_after_trial
)
SELECT churned_after_trial_count, ROUND((churned_after_trial_count / total_trial_count) * 100, 1)
FROM churned_after_trial, total_trial_customers;
# 307 customers churned at 30.7%

-- What is the number and percentage of customer plans after their initial free trial?
# same query with minor adjustments to values
WITH trial_customers AS
(SELECT customer_id
FROM subscriptions
WHERE plan_id = 0
),
stay_customers AS
(SELECT DISTINCT customer_id
FROM subscriptions
WHERE plan_id > 0
),
customers_after_trial AS
(SELECT t.customer_id
FROM trial_customers AS t
JOIN subscriptions AS s
	ON t.customer_id = s.customer_id
WHERE s.start_date > (SELECT sub.start_date
					FROM subscriptions AS sub
					WHERE sub.customer_id = t.customer_id
                    AND plan_id = 0)
	AND s.plan_id > 0
),
total_trial_customers AS
(SELECT COUNT(DISTINCT customer_id) AS total_trial_count
FROM trial_customers
),
stay_after_trial AS
(SELECT COUNT(DISTINCT customer_id) AS stay_after_trial_count
FROM customers_after_trial
)
SELECT stay_after_trial_count, ROUND((stay_after_trial_count / total_trial_count) * 100, 1)
FROM stay_after_trial, total_trial_customers;
# 1,000 customer plans at 100%

-- What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
# latest plan 
SELECT customer_id, plan_id, ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY start_date DESC) AS rn
FROM subscriptions
WHERE start_date <= '2020-12-31';

#current plan will be 1
WITH latest_plan AS
(SELECT customer_id, plan_id, ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY start_date DESC) AS rn
FROM subscriptions
WHERE start_date <= '2020-12-31'
)
SELECT lp.customer_id, lp.plan_id
FROM latest_plan AS lp
WHERE lp.rn = 1;

# count of plans
WITH latest_plan AS
(SELECT customer_id, plan_id, ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY start_date DESC) AS rn
FROM subscriptions
WHERE start_date <= '2020-12-31'
),
current_plan AS
(SELECT lp.customer_id, lp.plan_id
FROM latest_plan AS lp
WHERE lp.rn = 1
)
SELECT p.plan_name, COUNT(cp.customer_id) AS customer_count
FROM current_plan AS cp
JOIN plans AS p
	ON 	cp.plan_id = p.plan_id
GROUP BY p.plan_name;

WITH latest_plan AS
(SELECT customer_id, plan_id, ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY start_date DESC) AS rn
FROM subscriptions
WHERE start_date <= '2020-12-31'
),
current_plan AS
(SELECT lp.customer_id, lp.plan_id
FROM latest_plan AS lp
WHERE lp.rn = 1
),
plan_counts AS
(SELECT p.plan_name, COUNT(cp.customer_id) AS customer_count
FROM current_plan AS cp
JOIN plans AS p
	ON 	cp.plan_id = p.plan_id
GROUP BY p.plan_name
),
total_customers AS
(SELECT COUNT(DISTINCT customer_id) AS total_count
FROM current_plan
)
SELECT pc.plan_name, pc.customer_count, ROUND((pc.customer_count / tc.total_count) * 100, 1)
FROM plan_counts AS pc, total_customers AS tc
ORDER BY pc.plan_name;

-- How many customers have upgraded to an annual plan in 2020?
SELECT customer_id, plan_id
FROM subscriptions
WHERE start_date <= '2020-12-31';

SELECT COUNT(DISTINCT customer_id)
FROM subscriptions 
WHERE start_date <= '2020-12-31'
AND plan_id = 3;
# 195 customer upgraded 

-- How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
# first subscription
SELECT customer_id, MIN(start_date) AS first_start_date
FROM subscriptions
GROUP BY customer_id;

# dates where customer upgrade to annual plan
SELECT customer_id, start_date AS annual_start_date
FROM subscriptions
WHERE plan_id = 3;

# check the days between first sub and annual plan
WITH first_subscription AS
(SELECT customer_id, MIN(start_date) AS first_start_date
FROM subscriptions
GROUP BY customer_id
),
annual_plan_dates AS
(SELECT customer_id, start_date AS annual_start_date
FROM subscriptions
WHERE plan_id = 3
)
SELECT a.customer_id, a.annual_start_date - f.first_start_date AS day_to_annual
FROM annual_plan_dates AS a
JOIN first_subscription AS f
	ON a.customer_id = f.customer_id
;

# now check the avg
WITH first_subscription AS
(SELECT customer_id, MIN(start_date) AS first_start_date
FROM subscriptions
GROUP BY customer_id
),
annual_plan_dates AS
(SELECT customer_id, start_date AS annual_start_date
FROM subscriptions
WHERE plan_id = 3
),
days_to_annual AS
(SELECT a.customer_id, a.annual_start_date - f.first_start_date AS day_to_annual
FROM annual_plan_dates AS a
JOIN first_subscription AS f
	ON a.customer_id = f.customer_id
)
SELECT ROUND(AVG(day_to_annual))
FROM days_to_annual;
# takes about 2489 days on avg

-- Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
# add in a period query
WITH first_subscription AS
(SELECT customer_id, MIN(start_date) AS first_start_date
FROM subscriptions
GROUP BY customer_id
),
annual_plan_dates AS
(SELECT customer_id, start_date AS annual_start_date
FROM subscriptions
WHERE plan_id = 3
),
days_to_annual AS
(SELECT a.customer_id, a.annual_start_date - f.first_start_date AS days_to_annual
FROM annual_plan_dates AS a
JOIN first_subscription AS f
	ON a.customer_id = f.customer_id
)
SELECT customer_id, days_to_annual,
CASE
	WHEN days_to_annual BETWEEN 0 AND 30 THEN '0-30 days'
	WHEN days_to_annual BETWEEN 31 AND 60 THEN '31-60 days'
	WHEN days_to_annual BETWEEN 61 AND 90 THEN '61-90 days'
	WHEN days_to_annual BETWEEN 91 AND 120 THEN '91-120 days'
	WHEN days_to_annual BETWEEN 121 AND 150 THEN '121-150 days'
	WHEN days_to_annual BETWEEN 151 AND 180 THEN '151-180 days'
	WHEN days_to_annual BETWEEN 181 AND 210 THEN '181-210 days'
	WHEN days_to_annual BETWEEN 211 AND 240 THEN '211-240 days'
	WHEN days_to_annual BETWEEN 241 AND 270 THEN '241-270 days'
	WHEN days_to_annual BETWEEN 271 AND 300 THEN '271-300 days'
	WHEN days_to_annual BETWEEN 301 AND 330 THEN '301-330 days'
	WHEN days_to_annual BETWEEN 331 AND 360 THEN '331-360 days'
      ELSE '361+ days' 
END AS period
FROM days_to_annual;

WITH first_subscription AS
(SELECT customer_id, MIN(start_date) AS first_start_date
FROM subscriptions
GROUP BY customer_id
),
annual_plan_dates AS
(SELECT customer_id, start_date AS annual_start_date
FROM subscriptions
WHERE plan_id = 3
),
days_to_annual AS
(SELECT a.customer_id, a.annual_start_date - f.first_start_date AS days_to_annual
FROM annual_plan_dates AS a
JOIN first_subscription AS f
	ON a.customer_id = f.customer_id
),
periods AS
(SELECT customer_id, days_to_annual,
CASE
	WHEN days_to_annual BETWEEN 0 AND 30 THEN '0-30 days'
	WHEN days_to_annual BETWEEN 31 AND 60 THEN '31-60 days'
	WHEN days_to_annual BETWEEN 61 AND 90 THEN '61-90 days'
	WHEN days_to_annual BETWEEN 91 AND 120 THEN '91-120 days'
	WHEN days_to_annual BETWEEN 121 AND 150 THEN '121-150 days'
	WHEN days_to_annual BETWEEN 151 AND 180 THEN '151-180 days'
	WHEN days_to_annual BETWEEN 181 AND 210 THEN '181-210 days'
	WHEN days_to_annual BETWEEN 211 AND 240 THEN '211-240 days'
	WHEN days_to_annual BETWEEN 241 AND 270 THEN '241-270 days'
	WHEN days_to_annual BETWEEN 271 AND 300 THEN '271-300 days'
	WHEN days_to_annual BETWEEN 301 AND 330 THEN '301-330 days'
	WHEN days_to_annual BETWEEN 331 AND 360 THEN '331-360 days'
      ELSE '361+ days' 
END AS period
FROM days_to_annual
)
SELECT period, COUNT(customer_id)
FROM periods
GROUP BY period
ORDER BY MIN(days_to_annual);

-- How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
# check the previous plans for each current plan
SELECT s.customer_id, s.plan_id, s.start_date, LAG(s.plan_id) OVER (PARTITION BY s.customer_id ORDER BY s.start_date) AS previous_plan_id
FROM subscriptions AS s
WHERE s.start_date BETWEEN '2020-01-01' AND '2020-12-31';


# check the downgrades
WITH plan_change AS
(SELECT s.customer_id, s.plan_id, s.start_date, LAG(s.plan_id) OVER (PARTITION BY s.customer_id ORDER BY s.start_date) AS previous_plan_id
FROM subscriptions AS s
WHERE s.start_date BETWEEN '2020-01-01' AND '2020-12-31'
)
SELECT pc.customer_id, pc.previous_plan_id
FROM plan_change AS pc
JOIN plans AS p_current
	ON pc.plan_id = p_current.plan_id
JOIN plans AS p_previous
	ON pc.previous_plan_id = p_previous.plan_id
WHERE p_previous.plan_id = 3
	AND p_current.plan_id = 1;
# there seems to be no value, could have no downgrades

WITH plan_change AS
(SELECT s.customer_id, s.plan_id, s.start_date, LAG(s.plan_id) OVER (PARTITION BY s.customer_id ORDER BY s.start_date) AS previous_plan_id
FROM subscriptions AS s
WHERE s.start_date BETWEEN '2020-01-01' AND '2020-12-31'
),
downgrades AS
(SELECT pc.customer_id, pc.previous_plan_id
FROM plan_change AS pc
JOIN plans AS p_current
	ON pc.plan_id = p_current.plan_id
JOIN plans AS p_previous
	ON pc.previous_plan_id = p_previous.plan_id
WHERE p_previous.plan_id = 3
	AND p_current.plan_id = 1
)
SELECT COUNT(DISTINCT customer_id)
FROM downgrades;
# there were no downgrades

    