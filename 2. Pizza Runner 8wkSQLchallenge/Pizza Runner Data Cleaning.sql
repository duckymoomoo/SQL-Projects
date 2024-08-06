SELECT *
FROM customer_orders;

SELECT *
FROM pizza_names;

SELECT *
FROM pizza_recipes;

SELECT *
FROM pizza_toppings;

SELECT * 
FROM runner_orders;

SELECT *
FROM runners;

# Cleaning customer_orders table
# Change all blanks and 'null' to NULL 
Update customer_orders
SET exclusions = NULL
WHERE exclusions = 'null'
;

Update customer_orders
SET exclusions = NULL
WHERE exclusions = 'null'
;

Update customer_orders
SET extras = NULL
WHERE extras = 'null'
;

Update customer_orders
SET extras = NULL
WHERE extras = ''
;

# Cleaning runner_orders table
# Change all blanks and 'null' to NULL
Update runner_orders
SET pickup_time = NULL
WHERE pickup_time = 'null'
;

Update runner_orders
SET distance = NULL
WHERE distance = 'null'
;

Update runner_orders
SET duration = NULL
WHERE duration = 'null'
;

Update runner_orders
SET cancellation = NULL
WHERE cancellation = 'null'
;

Update runner_orders
SET cancellation = NULL
WHERE cancellation = ''
;

# Change format on pickup_time from varchar to timestamp
UPDATE runner_orders
SET pickup_time = STR_TO_DATE(pickup_time, '%Y-%m-%d %H:%i:%s')
;

ALTER TABLE runner_orders
MODIFY COLUMN pickup_time TIMESTAMP
;

# remove 'km' from distance for easier calculation
UPDATE runner_orders
SET distance = CAST(REPLACE(distance, 'km', '') AS DECIMAL(5,1))
;

# Change format on distance from varchar to float
ALTER TABLE runner_orders
MODIFY COLUMN distance FLOAT
;

# standardise duration column to numerical value
UPDATE runner_orders
SET duration = 
CASE
	WHEN duration LIKE '%minute%' THEN CAST(REPLACE(REPLACE(REPLACE(duration, 'minutes', ''), 'minute', ''), 'mins', '') AS UNSIGNED)
END
;

# Change format on duration from varchar to INT
ALTER TABLE runner_orders
MODIFY COLUMN duration INT
;

