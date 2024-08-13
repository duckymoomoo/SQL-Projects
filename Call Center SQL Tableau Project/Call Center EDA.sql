-- Only managed to import 18,137 rows of data as file was too large
-- I will do EDA based on the existing data imported
-- Link to Tableau dashboard https://public.tableau.com/app/profile/phua.en.yew/viz/CallCenterDataProject_17235569382680/Dashboard1
SELECT *
FROM call_center;

-- Check the avg csat scores of call centers
Select call_center, AVG(csat_score)
FROM call_center
GROUP BY call_center;
# Table 1

-- Check the distribution of sentiments
SELECT sentiment, COUNT(*) AS count
FROM call_center
GROUP BY sentiment;
# Table 2

-- Check the call volume over time
-- Change call_timestamp column to date format first
SELECT call_timestamp, STR_TO_DATE(call_timestamp,'%m/%d/%Y')
FROM call_center;

UPDATE call_center
SET call_timestamp = STR_TO_DATE(call_timestamp,'%m/%d/%Y');

ALTER TABLE call_center
MODIFY COLUMN call_timestamp DATE;

SELECT call_timestamp, COUNT(*) AS call_count
FROM call_center
GROUP BY call_timestamp
ORDER BY call_timestamp;
# Table 3

-- check count of response time
SELECT response_time, COUNT(*) AS count
FROM call_center
GROUP BY response_time
ORDER BY response_time;
# Table 4

-- check average call duration by channel
-- change `call duration in minutes` column name
ALTER TABLE call_center
CHANGE COLUMN `call duration in minutes` call_duration TEXT;

SELECT `channel`, ROUND(AVG(call_duration),1) AS avg_time
FROM call_center
GROUP BY `channel`;
# Table 5

-- check call volume by region and state
SELECT city, state, COUNT(*) AS count
FROM call_center
GROUP BY city, state
ORDER BY count;
# Table 6

-- check avg csat score given by region
SELECT city, state, ROUND(AVG(csat_score),2) AS avg_score
FROM call_center
GROUP BY city, state;
# Table 7

-- check call volume by channel
SELECT `channel`, COUNT(*) AS call_count
FROM call_center
GROUP BY `channel`;
# Table 8

-- check common reasons for calls
SELECT reason, COUNT(*) AS reason_count
FROM call_center
GROUP BY reason
ORDER BY reason_count DESC;
# Table 9

-- check call center performance
SELECT call_center, COUNT(*) AS call_count, ROUND(AVG(csat_score),2) AS avg_score
FROM call_center
GROUP BY call_center
ORDER BY call_count DESC;
# Table 10

-- Check csat scores over time
SELECT call_timestamp, ROUND(AVG(csat_score),2) AS score
FROM call_center
GROUP BY call_timestamp
ORDER BY call_timestamp;
# Table 11