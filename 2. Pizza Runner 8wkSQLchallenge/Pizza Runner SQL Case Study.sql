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

-- A. Pizza Metrics
-- How many pizzas were ordered?
SELECT COUNT(pizza_id)
FROM customer_orders;
# 14 pizzas ordered

-- How many unique customer orders were made?
SELECT COUNT(DISTINCT pizza_id) AS unique_orders
FROM customer_orders;
# 2 unique customer orders

-- How many successful orders were delivered by each runner?
SELECT runner_id, COUNT(order_id) AS successful_orders
FROM runner_orders
WHERE cancellation IS NULL 
GROUP BY runner_id;
# Runner 1 delivered 4 orders, 2 delivered 3, 3 delivered 1

-- How many of each type of pizza was delivered?
SELECT pn.pizza_name, COUNT(co.pizza_id)
FROM customer_orders AS co
JOIN pizza_names AS pn
	ON co.pizza_id = pn.pizza_id
JOIN runner_orders AS ro
	ON co.order_id = ro.order_id
WHERE ro.cancellation IS NULL 
GROUP BY pn.pizza_name;
# 9 Meatlovers delivered, 3 Vegetarian delivered

-- How many Vegetarian and Meatlovers were ordered by each customer?
SELECT co.customer_id, pn.pizza_name, COUNT(co.pizza_id) AS pizza_ordered
FROM customer_orders AS co
JOIN pizza_names AS pn
	ON co.pizza_id = pn.pizza_id
GROUP BY co.customer_id, pn.pizza_name
ORDER BY co.customer_id;
# 101 and 102 bought 2Meat 1 Veg, 103 bought 3Meat 1Veg, 104 bought 3Meat, 105 bought 1Veg

-- What was the maximum number of pizzas delivered in a single order?
SELECT order_id, COUNT(pizza_id)
FROM customer_orders
GROUP BY order_id;

SELECT co.order_id, COUNT(co.pizza_id)
FROM customer_orders AS co
JOIN runner_orders AS ro
	ON co.order_id = ro.order_id
WHERE cancellation IS NULL
GROUP BY co.order_id
ORDER BY COUNT(pizza_id) DESC;
# Max of 3 pizzas delivered in a single order

-- For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
SELECT co.customer_id,
	SUM(CASE
		WHEN co.exclusions IS NOT NULL
        OR co.extras IS NOT NULL
        THEN 1 ELSE 0
        END) AS pizza_changes,
	SUM(CASE
		WHEN co.exclusions IS NULL
        AND co.extras IS NULL
        THEN 1 ELSE 0
        END) AS pizza_nochanges
FROM customer_orders AS co
JOIN runner_orders AS ro
	ON co.order_id = ro.order_id
WHERE ro.cancellation IS NULL
GROUP BY co.customer_id;
# 101 had 2 with no change, 102 had 3 with no change, 103 had 3 with change, 104 had 2 with change and 1 with no change, 105 had 1 with change

-- How many pizzas were delivered that had both exclusions and extras?
SELECT co.order_id, 
	SUM(CASE
		WHEN co.exclusions IS NOT NULL
        AND co.extras IS NOT NULL
        THEN 1 ELSE 0
        END) AS pizza_2change
FROM customer_orders AS co
JOIN runner_orders AS ro
	ON co.order_id = ro.order_id
WHERE ro.cancellation IS NULL
GROUP BY co.order_id
ORDER BY pizza_2change DESC
;
# 1 pizza delivered with exclusion and extra

-- What was the total volume of pizzas ordered for each hour of the day?
SELECT *
FROM customer_orders
ORDER BY order_time;

SELECT EXTRACT(HOUR FROM order_time) AS order_hour, COUNT(*) AS pizza_ordered
FROM customer_orders
GROUP BY order_hour
ORDER BY order_hour;
# 11am 1 pizza, 1pm 3 pizza, 6pm 3 pizza, 7pm 1 pizza, 9pm 3 pizza, 11pm 3 pizza

-- What was the volume of orders for each day of the week?
SELECT DAYOFWEEK(order_time) AS day_number, DAYNAME(order_time) AS day_of_week, COUNT(*) AS total_orders
FROM customer_orders
GROUP BY day_number, day_of_week
ORDER BY day_number;
# Wed 5 orders, Thurs 3 orders, Fri 1 order, Sat 5 orders

-- B. Runner and Customer Experience
-- How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
SELECT DATE_SUB(registration_date, INTERVAL(WEEKDAY(registration_date)) DAY) AS week_start, COUNT(*) AS sign_up
FROM runners
GROUP BY week_start
ORDER BY week_start;
# 2 runners signed up in 1st week, 1 runner in 2nd week, 1 runner in 3rd week

-- What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
SELECT co.order_time, ro.runner_id, ro.pickup_time
FROM customer_orders AS co
JOIN runner_orders AS ro
	ON co.order_id = ro.order_id
;

SELECT ro.runner_id, AVG(TIMESTAMPDIFF(MINUTE, co.order_time, ro.pickup_time)) AS avg_time
FROM customer_orders AS co
JOIN runner_orders AS ro
	ON co.order_id = ro.order_id
WHERE ro.pickup_time IS NOT NULL 
AND ro.cancellation IS NULL
GROUP BY runner_id
;
# runner 1 took avg 15.3mins, runner 2 23.4mins, runner 3 10mins

-- Is there any relationship between the number of pizzas and how long the order takes to prepare?
SELECT co.order_id, COUNT(co.pizza_id) AS pizza_num, AVG(TIMESTAMPDIFF(MINUTE, co.order_time, ro.pickup_time)) AS avg_time
FROM customer_orders AS co
JOIN runner_orders AS ro
	ON co.order_id = ro.order_id
WHERE ro.pickup_time IS NOT NULL 
AND ro.cancellation IS NULL
GROUP BY co.order_id
ORDER BY pizza_num;
# no relationship as the avg_time is not consistent with number of pizzas prepared

-- What was the average distance travelled for each customer?
SELECT co.customer_id, AVG(ro.distance)
FROM customer_orders AS co
JOIN runner_orders AS ro
	ON co.order_id = ro.order_id
WHERE ro.distance IS NOT NULL
GROUP BY co.customer_id
;
# Avg 20km for customer 101, 16.7km for 102, 23.4km for 103, 10km for 104, 25km for 105

-- What was the difference between the longest and shortest delivery times for all orders?
SELECT MAX(duration), MIN(duration), MAX(duration)-MIN(duration) AS time_diff
FROM runner_orders
WHERE duration IS NOT NULL
;
# 22mins

-- What was the average speed for each runner for each delivery and do you notice any trend for these values?
SELECT runner_id, order_id, distance, duration,
CASE
	WHEN duration > 0 THEN distance/duration
    ELSE NULL
END AS avg_speed
FROM runner_orders
WHERE distance IS NOT NULL
AND duration IS NOT NULL
;
# runner 3 excluded because duration is NULL. Runner 2 seems to be the faster then runner 1

-- What is the successful delivery percentage for each runner?
SELECT runner_id, COUNT(*) AS total_deliveries,
SUM(CASE
	WHEN cancellation IS NULL
    THEN 1
    ELSE 0
    END) AS successful_deliveries
FROM runner_orders
GROUP BY runner_id
;

WITH delivery_count AS
(SELECT runner_id, COUNT(*) AS total_deliveries,
SUM(CASE
	WHEN cancellation IS NULL
    THEN 1
    ELSE 0
    END) AS successful_deliveries
FROM runner_orders
GROUP BY runner_id)
SELECT runner_id, total_deliveries, successful_deliveries, (successful_deliveries/total_deliveries) * 100 AS successful_percentage
FROM delivery_count
;
# runner 1 100% success, 2 75%, 3 50%

-- C. Ingredient Optimisation
-- What are the standard ingredients for each pizza?
# not sure how to do this

-- What was the most commonly added extra?
# generate a table for extras
SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(extras, ',', numbers.n), ',', -1)) AS extra
FROM customer_orders
JOIN (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 ) AS numbers
    ON CHAR_LENGTH(extras) - CHAR_LENGTH(REPLACE(extras, ',', '')) >= numbers.n - 1
WHERE extras IS NOT NULL;

WITH extra_items AS 
(SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(extras, ',', numbers.n), ',', -1)) AS extra
FROM customer_orders
JOIN (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 ) AS numbers
    ON CHAR_LENGTH(extras) - CHAR_LENGTH(REPLACE(extras, ',', '')) >= numbers.n - 1
WHERE extras IS NOT NULL)
SELECT extra, COUNT(*) AS count
FROM extra_items
GROUP BY extra
ORDER BY count DESC;
# Bacon is the most common extra

-- What was the most common exclusion?
WITH excl_items AS 
(SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(exclusions, ',', numbers.n), ',', -1)) AS excl
FROM customer_orders
JOIN (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 ) AS numbers
    ON CHAR_LENGTH(exclusions) - CHAR_LENGTH(REPLACE(exclusions, ',', '')) >= numbers.n - 1
WHERE exclusions IS NOT NULL)
SELECT excl, COUNT(*) AS count
FROM excl_items
GROUP BY excl
ORDER BY count DESC;
# Cheese is the most common exclusion

-- Generate an order item for each record in the customers_orders table in the format of one of the following:
-- Meat Lovers
-- Meat Lovers - Extra Bacon
-- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
-- Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
-- What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
# not sure how to do these

-- D. Pricing and Ratings
-- If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
SELECT SUM(CASE
			WHEN pizza_id = 1 THEN 12
            WHEN pizza_id = 2 THEN 10
            ELSE 0
            END) as revenue
FROM customer_orders ;
# Pizza Runner has made $160 so far

-- What if there was an additional $1 charge for any pizza extras? Add cheese is $1 extra
SELECT SUM(CASE
			WHEN pizza_id = 1 THEN 12
            WHEN pizza_id = 2 THEN 10
            ELSE 0
            END
            +
            CASE
            WHEN extras IS NOT NULL THEN 1
            ELSE 0
            END
            +
            CASE 
            WHEN FIND_IN_SET(4, extras) > 0 THEN 1
            ELSE 0
            END
            ) AS revenue
FROM customer_orders ;
# Pizza Runner has made $164 so far

-- The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
CREATE TABLE order_ratings(
	order_id INT,
    runner_id INT,
    rating INT UNSIGNED NOT NULL CHECK(rating BETWEEN 1 AND 5)
);

INSERT INTO order_ratings(order_id, runner_id, rating) 
	VALUES
	(1, 1, 4),
    (2, 1, 5),
    (3, 2, 3),
    (4, 2, 4),
    (5, 3, 2),
    (6, 3, 5),
    (7, 2, 3),
    (8, 2, 4),
    (9, 1, 5),
    (10, 1, 4);

SELECT *
FROM order_ratings;

-- Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
-- customer_id, order_id, runner_id, rating ,order_time, pickup_time, Time between order and pickup, Delivery duration, Average speed ,Total number of pizzas
SELECT runner_id, order_id, distance, duration,
CASE
	WHEN duration > 0 THEN distance/duration
    ELSE NULL
END AS avg_speed
FROM runner_orders
WHERE distance IS NOT NULL
AND duration IS NOT NULL
;

WITH average_speed AS
(SELECT runner_id, order_id, distance, duration,
CASE
	WHEN duration > 0 THEN distance/duration
    ELSE NULL
END AS avg_speed
FROM runner_orders
WHERE distance IS NOT NULL
AND duration IS NOT NULL
)

SELECT co.customer_id, co.order_id, ro.runner_id, r.rating, co.order_time, ro.pickup_time, 
	TIMESTAMPDIFF(MINUTE, co.order_time, ro.pickup_time) AS time_btw_order_and_pickup, 
    ro.duration, 
    CASE
		WHEN ro.duration > 0 THEN (ro.distance / ro.duration)
        ELSE NULL
        END AS avg_speed, 
	(SELECT COUNT(*)
		FROM customer_orders AS co_sub
		WHERE co_sub.order_id = co.order_id) AS number_of_pizza
FROM customer_orders AS co
JOIN runner_orders AS ro
	ON co.order_id = ro.order_id
LEFT JOIN order_ratings AS r
	ON r.order_id = ro.order_id
WHERE ro.cancellation IS NULL
;

-- If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?
SELECT co.order_id, co.pizza_id, 
	CASE
    WHEN co.pizza_id = 1 THEN 12
    WHEN co.pizza_id = 2 THEN 10
    ELSE 0
    END AS price,
    ro.distance
FROM customer_orders AS co
JOIN runner_orders AS ro
	ON co.order_id = ro.order_id
WHERE ro.cancellation IS NULL
;

WITH CTE_example AS 
(SELECT co.order_id, co.pizza_id, 
	CASE
    WHEN co.pizza_id = 1 THEN 12
    WHEN co.pizza_id = 2 THEN 10
    ELSE 0
    END AS price,
    ro.distance
FROM customer_orders AS co
JOIN runner_orders AS ro
	ON co.order_id = ro.order_id
WHERE ro.cancellation IS NULL
)
SELECT SUM(price - (distance * 0.3)) AS leftover
FROM CTE_example
;
# Pizza Runner would have approx $73.38 left over

-- E. Bonus Questions
-- If Danny wants to expand his range of pizzas - how would this impact the existing data design? Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?
INSERT INTO pizza_names (pizza_id, pizza_name)
VALUES (3, 'Supreme');

# Assume that the Supreme consists of all toppings, retrieve data of all toppings
SELECT GROUP_CONCAT(topping_id ORDER BY topping_id) AS all_toppings
FROM pizza_toppings;

INSERT INTO pizza_recipes (pizza_id, toppings)
VALUES (3, '1,2,3,4,5,6,7,8,9,10,11,12');