-- Link to Case Study https://8weeksqlchallenge.com/case-study-1/
-- 1. What is the total amount each customer spent at the restaurant?
-- 2. How many days has each customer visited the restaurant?
-- 3. What was the first item from the menu purchased by each customer?
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
-- 5. Which item was the most popular for each customer?
-- 6. Which item was purchased first by the customer after they became a member?
-- 7. Which item was purchased just before the customer became a member?
-- 8. What is the total items and amount spent for each member before they became a member?
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

SELECT *
FROM sales;

SELECT *
FROM menu;

SELECT *
FROM members;



-- 1. What is the total amount each customer spent at the restaurant?
SELECT customer_id, sales.product_id, price
FROM sales
JOIN menu
	ON sales.product_id = menu.product_id
;

WITH customer_spend AS
(SELECT customer_id, sales.product_id, price
FROM sales
JOIN menu
	ON sales.product_id = menu.product_id
)
SELECT customer_id, SUM(price)
FROM customer_spend
GROUP BY customer_id
;
-- Customer A spent 76, B spent 74, C spend 36

-- 2. How many days has each customer visited the restaurant?
SELECT customer_id, COUNT(*) AS visit_count
FROM sales
GROUP BY customer_id
;
-- Customer A visited 6 times, B visited 6, C visited 3

-- 3. What was the first item from the menu purchased by each customer?
 # rank the dates in order of customers
SELECT sales.customer_id, sales.order_date, sales.product_id, menu.product_name, ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY order_date ASC) AS row_num 
FROM sales
JOIN menu
	ON sales.product_id = menu.product_id
;

WITH first_item AS
(SELECT sales.customer_id, sales.order_date, sales.product_id, menu. product_name, ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date ASC) AS row_num
FROM sales
JOIN menu
	ON sales.product_id = menu.product_id
)
SELECT customer_id, product_name
FROM first_item
WHERE row_num = 1
;
-- Customer A bought sushi, B bought curry, C bought ramen

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
 # find the number of purchases for each product
SELECT product_id, COUNT(*) AS purchase_count  
FROM sales
GROUP BY product_id
;

WITH item_count AS
(SELECT product_id, COUNT(*) AS purchase_count
FROM sales
GROUP BY product_id
)
SELECT menu.product_name, item_count.purchase_count
FROM item_count 
JOIN menu
	ON item_count.product_id = menu.product_id
ORDER BY item_count.purchase_count DESC
;
 -- RAMEN is most purchased with 8 purchased

-- 5. Which item was the most popular for each customer?
# find how many times each product was bought by each customer
SELECT customer_id, product_id, COUNT(*) AS purchase_count   
FROM sales
GROUP BY customer_id, product_id
;

 # rank the purchase_count in order by customer
WITH product_count AS   
(SELECT customer_id, product_id, COUNT(*) AS purchase_count  
GROUP BY customer_id, product_id
)
SELECT customer_id, product_id, purchase_count, ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY purchase_count DESC) AS purchase_rank
FROM product_count
;

WITH product_count AS
(SELECT customer_id, product_id, COUNT(*) AS purchase_count   
FROM sales
GROUP BY customer_id, product_id
), rank_products AS 
(SELECT customer_id, product_id, purchase_count, ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY purchase_count DESC) AS purchase_rank
FROM product_count
)
SELECT rank_products.customer_id, rank_products.product_id, rank_products.purchase_count, menu.product_name
FROM rank_products
JOIN menu
	ON rank_products.product_id = menu.product_id
WHERE purchase_rank = 1
ORDER BY customer_id
;
-- Ramen popular for A and C, Curry popular for B

-- 6. Which item was purchased first by the customer after they became a member?
SELECT s.customer_id, s.order_date, s.product_id, m.product_name
FROM sales AS s
JOIN menu AS m
	ON s.product_id = m.product_id
JOIN members AS mb
	ON s.customer_id = mb.customer_id
WHERE s.order_date >= mb.join_date
ORDER BY customer_id
;

WITH first_order AS
(SELECT s.customer_id, s.order_date, s.product_id, m.product_name
FROM sales AS s
JOIN menu AS m
	ON s.product_id = m.product_id
JOIN members AS mb
	ON s.customer_id = mb.customer_id
WHERE s.order_date >= mb.join_date
ORDER BY customer_id
)
SELECT customer_id, order_date, product_name, ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY order_date ASC) AS `rank`
FROM first_order
;

WITH first_order AS
(SELECT s.customer_id, s.order_date, s.product_id, m.product_name
FROM sales AS s
JOIN menu AS m
	ON s.product_id = m.product_id
JOIN members AS mb
	ON s.customer_id = mb.customer_id
WHERE s.order_date >= mb.join_date
ORDER BY customer_id
), food_rank AS
(SELECT customer_id, order_date, product_name, ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY order_date ASC) AS `rank`
FROM first_order
)
SELECT customer_id, order_date, product_name
FROM food_rank
WHERE `rank` = 1
;
-- A purchased curry, B purchased sushi

-- 7. Which item was purchased just before the customer became a member?
SELECT s.customer_id, s.order_date, s.product_id, m.product_name
FROM sales AS s
JOIN menu AS m
	ON s.product_id = m.product_id
JOIN members AS mb
	ON s.customer_id = mb.customer_id
WHERE s.order_date < mb.join_date
ORDER BY customer_id
;

WITH last_order AS
(SELECT s.customer_id, s.order_date, s.product_id, m.product_name
FROM sales AS s
JOIN menu AS m
	ON s.product_id = m.product_id
JOIN members AS mb
	ON s.customer_id = mb.customer_id
WHERE s.order_date < mb.join_date
ORDER BY customer_id
)
SELECT customer_id, order_date, product_id, product_name, DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY order_date DESC) AS `rank`
FROM last_order
;

WITH last_order AS
(SELECT s.customer_id, s.order_date, s.product_id, m.product_name
FROM sales AS s
JOIN menu AS m
	ON s.product_id = m.product_id
JOIN members AS mb
	ON s.customer_id = mb.customer_id
WHERE s.order_date < mb.join_date
ORDER BY customer_id
), food_rank AS
(SELECT customer_id, order_date, product_id, product_name, DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY order_date DESC) AS `rank`
FROM last_order
)
SELECT customer_id, order_date, product_name
FROM food_rank
WHERE `rank` = 1
;
-- A purchased sushi & curry, B purchased sushi

-- 8. What is the total items and amount spent for each member before they became a member?
SELECT s.customer_id, s.product_id, m.price
FROM sales AS s
JOIN menu AS m
	ON s.product_id = m.product_id
JOIN members AS mb
	ON s.customer_id = mb.customer_id
WHERE s.order_date < mb.join_date
ORDER BY s.customer_id
;

SELECT s.customer_id, COUNT(s.product_id) AS item_count, SUM(m.price) AS spent
FROM sales AS s
JOIN menu AS m
	ON s.product_id = m.product_id
JOIN members AS mb
	ON s.customer_id = mb.customer_id
WHERE s.order_date < mb.join_date
GROUP BY s.customer_id
;
-- A spent $50 on 4 items, B spent $80 on 6 items

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT s.customer_id, s.product_id, m.product_name, m.price
FROM sales AS s
JOIN menu AS m
	ON s.product_id = m.product_id
JOIN members AS mb
	ON s.customer_id = mb.customer_id
;

SELECT s.customer_id, 
SUM(CASE
WHEN s.product_id > 1 THEN m.price * 10
ELSE m.price * 20
END) AS points
FROM sales AS s
JOIN menu AS m
	ON s.product_id = m.product_id
JOIN members AS mb
	ON s.customer_id = mb.customer_id
GROUP BY customer_id
;
-- A has 1720 points, B has 1880 points

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
SELECT s.customer_id, s.order_date, s.product_id, m.product_name, m.price
FROM sales AS s
JOIN menu AS m
	ON s.product_id = m.product_id
JOIN members AS mb
	ON s.customer_id = mb.customer_id
;

SELECT s.customer_id,
SUM(CASE 
WHEN s.order_date BETWEEN mb.join_date AND DATE_ADD(mb.join_date, INTERVAL 6 DAY) THEN m.price * 20
ELSE CASE
	WHEN s.product_id > 1 THEN m.price * 10
	ELSE m.price * 20
	END
END) AS total_points
FROM sales s
JOIN members mb 
    ON s.customer_id = mb.customer_id
JOIN menu m 
    ON s.product_id = m.product_id
WHERE s.order_date <= '2021-01-31' 
GROUP BY s.customer_id
;
-- A has 2740 points, B has 1640 points

-- BONUS QUESTION 1
SELECT s.customer_id, s.order_date, m.product_name, m.price
FROM sales AS s
JOIN menu AS m
	ON s.product_id = m.product_id
JOIN members AS mb
	ON s.customer_id = mb.customer_id
;

SELECT s.customer_id, s.order_date, m.product_name, m.price,
CASE 
	WHEN s.order_date >= mb.join_date THEN 'Y'
    ELSE 'N'
END AS `member`
FROM sales AS s
JOIN menu AS m
	ON s.product_id = m.product_id
LEFT JOIN members AS mb
	ON s.customer_id = mb.customer_id
ORDER BY customer_id, order_date, product_name
;

CREATE TABLE membership AS
SELECT s.customer_id, s.order_date, m.product_name, m.price,
CASE 
	WHEN s.order_date >= mb.join_date THEN 'Y'
    ELSE 'N'
END AS `member`
FROM sales AS s
JOIN menu AS m
	ON s.product_id = m.product_id
LEFT JOIN members AS mb
	ON s.customer_id = mb.customer_id
ORDER BY customer_id, order_date, product_name
;

-- BONUS QUESTION 2
SELECT s.customer_id, s.order_date, m.product_name, m.price,
CASE 
	WHEN s.order_date >= mb.join_date THEN 'Y'
    ELSE 'N'
END AS `member`,
CASE 
	WHEN s.order_date >= mb.join_date THEN RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date, m.product_name)
    ELSE NULL
END AS `rank`
FROM sales AS s
JOIN menu AS m
	ON s.product_id = m.product_id
LEFT JOIN members AS mb
	ON s.customer_id = mb.customer_id
;

CREATE TABLE membership_rank AS
SELECT s.customer_id, s.order_date, m.product_name, m.price,
CASE 
	WHEN s.order_date >= mb.join_date THEN 'Y'
    ELSE 'N'
END AS `member`,
CASE 
	WHEN s.order_date >= mb.join_date THEN RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date, m.product_name)
    ELSE NULL
END AS `rank`
FROM sales AS s
JOIN menu AS m
	ON s.product_id = m.product_id
LEFT JOIN members AS mb
	ON s.customer_id = mb.customer_id
;

