--1.Import the dataset and do usual exploratory analysis steps like checking the
--  structure & characteristics of the dataset:


-- #1. Data type of all columns in the "customers" table. 

SELECT * FROM `target_sql.customers`
LIMIT 10;

-- #2. Get the time range between which the orders were placed.

SELECT
MIN(order_purchase_timestamp) AS first_order,
MAX(order_purchase_timestamp) AS last_order
FROM `target_sql.orders`;

-- #3. Count the Cities & States of customers who ordered during the given period.

SELECT
COUNT(DISTINCT c.customer_city) AS total_cities,
COUNT(DISTINCT c.customer_state) AS total_states
FROM `target_sql.orders` o
JOIN `target_sql.customers` c
ON o.customer_id = c.customer_id
WHERE EXTRACT(YEAR FROM o.order_purchase_timestamp) = 2018
AND EXTRACT(MONTH FROM o.order_purchase_timestamp) BETWEEN 1 AND 3;

-- #4. Is there a growing trend in the no. of orders placed over the past years?

SELECT
EXTRACT(YEAR FROM order_purchase_timestamp) AS year,
COUNT(order_id) AS no_of_orders
FROM `target_sql.orders`
GROUP BY year
ORDER BY year;

-- #5. Can we see some kind of monthly seasonality in terms of the no. of orders being placed?

SELECT 
EXTRACT(YEAR FROM order_purchase_timestamp) AS year, 
EXTRACT(MONTH FROM order_purchase_timestamp) AS month, 
COUNT(order_id) AS no_of_orders
FROM `target_sql.orders`
GROUP BY year, month
ORDER BY year, no_of_orders DESC;

-- #6. During what time of the day, do the Brazilian customers mostly place their orders?
-- #(Dawn, Morning, Afternoon or Night)
-- #0-6 hrs : Dawn
-- #7-12 hrs : Mornings
-- #13-18 hrs : Afternoon
-- #19-23 hrs : Night

WITH cte AS (
SELECT
CASE
WHEN EXTRACT(HOUR FROM order_purchase_timestamp) BETWEEN 0 AND 6 THEN 'Dawn'
WHEN EXTRACT(HOUR FROM order_purchase_timestamp) BETWEEN 7 AND 12 THEN 'Morning'
WHEN EXTRACT(HOUR FROM order_purchase_timestamp) BETWEEN 13 AND 18 THEN 'Afternoon'
WHEN EXTRACT(HOUR FROM order_purchase_timestamp) BETWEEN 19 AND 23 THEN 'Night'
END AS interval_of_day
FROM `target_sql.orders`
)
SELECT interval_of_day, COUNT(*) AS no_of_orders
FROM cte
GROUP BY interval_of_day;


-- #7. Get the month on month no. of orders placed in each state.

WITH cte AS 
 (SELECT o.order_id, c.customer_state, EXTRACT(MONTH FROM o.order_purchase_timestamp) AS month,
 EXTRACT(YEAR FROM o.order_purchase_timestamp) AS year
 FROM `target_sql.orders` AS o
 INNER JOIN `target_sql.customers` c 
 ON o.customer_id = c.customer_id)

SELECT customer_state, month, year, COUNT(order_id) AS no_of_orders
FROM cte
GROUP BY customer_state, month, year
ORDER BY customer_state, month, year;

-- #8. How are the customers distributed across all the states?

SELECT customer_state, COUNT(DISTINCT customer_unique_id) AS no_of_customers
FROM `target_sql.customers`
GROUP BY customer_state
ORDER BY no_of_customers DESC;

-- #9. Get the % increase in the cost of orders from year 2017 to 2018
-- #(include months between Jan to Aug only).

WITH yearly_totals AS
(SELECT EXTRACT(YEAR FROM o.order_purchase_timestamp) AS year,
ROUND(SUM(p.payment_value),2) AS total_payment
FROM `target_sql.payments` p 
JOIN `target_sql.orders` o
ON p.order_id = o.order_id
WHERE EXTRACT(YEAR FROM o.order_purchase_timestamp) IN (2017,2018)
AND EXTRACT(MONTH FROM o.order_purchase_timestamp) BETWEEN 1 AND 8
GROUP BY year) 

SELECT
ROUND(100 * 
(MAX(CASE WHEN year = 2018 THEN total_payment END) -
MAX(CASE WHEN year = 2017 THEN total_payment END)) /
MAX(CASE WHEN year = 2017 THEN total_payment END), 2) AS percent_increase
FROM yearly_totals;

-- #10. Calculate the Total & Average value of order price and order freight for each state.

SELECT
c.customer_state,
ROUND(SUM(o2.price), 0) AS total_price,
ROUND(AVG(o2.price), 0) AS avg_price,
ROUND(SUM(o2.freight_value), 0) AS total_freight_value,
ROUND(AVG(o2.freight_value), 0) AS avg_freight_value
FROM `target_sql.orders` AS o1 
JOIN `target_sql.order_items` AS o2
ON o1.order_id = o2.order_id
JOIN `target_sql.customers` AS c 
ON o1.customer_id = c.customer_id
GROUP BY c.customer_state
ORDER BY c.customer_state;

-- #11. Find the no. of days taken to deliver each order from the order’s
-- #purchase date as delivery time.
-- #Also, calculate the difference (in days) between the estimated & actual
-- #delivery date of an order.

SELECT
order_id,
DATE_DIFF(DATE(order_delivered_customer_date),DATE(order_purchase_timestamp),DAY) 
AS time_to_deliver,
DATE_DIFF(DATE(order_delivered_customer_date),DATE(order_estimated_delivery_date),DAY)
AS diff_estimated_delivery
FROM `target_sql.orders`
WHERE order_status='delivered';

-- #12. Find out the top 5 states with the highest & lowest average freight value.

#HIGHEST

SELECT c.customer_state, 
ROUND(AVG(freight_value),2) AS avg_freight_value
FROM `target_sql.orders` AS o1 
JOIN `target_sql.order_items` AS o2
ON o1.order_id = o2.order_id
JOIN `target_sql.customers` AS c 
ON o1.customer_id = c.customer_id
GROUP BY c.customer_state
ORDER BY avg_freight_value DESC
LIMIT 5;

#LOWEST

SELECT c.customer_state, 
ROUND(AVG(freight_value),2) AS avg_freight_value
FROM `target_sql.orders` AS o1 
JOIN `target_sql.order_items` AS o2
ON o1.order_id = o2.order_id
JOIN `target_sql.customers` AS c 
ON o1.customer_id = c.customer_id
GROUP BY c.customer_state
ORDER BY avg_freight_value ASC
LIMIT 5;

-- #13. Find out the top 5 states with the highest & lowest average delivery time.

#HIGHEST

SELECT c.customer_state, 
AVG(EXTRACT(DATE FROM o1.order_delivered_customer_date) - EXTRACT( DATE FROM o1.order_purchase_timestamp)) AS avg_time_to_delivery
FROM `target_sql.orders` AS o1 
JOIN `target_sql.order_items` AS o2
ON o1.order_id = o2.order_id
JOIN `target_sql.customers` AS c 
ON o1.customer_id = c.customer_id
GROUP BY c.customer_state
ORDER BY avg_time_to_delivery DESC
LIMIT 5;

#LOWEST

SELECT c.customer_state, 
AVG(EXTRACT(DATE FROM o1.order_delivered_customer_date) - EXTRACT( DATE FROM o1.order_purchase_timestamp)) AS avg_time_to_delivery
FROM `target_sql.orders` AS o1 
JOIN `target_sql.order_items` AS o2
ON o1.order_id = o2.order_id
JOIN `target_sql.customers` AS c 
ON o1.customer_id = c.customer_id
GROUP BY c.customer_state
ORDER BY avg_time_to_delivery ASC
LIMIT 5;

-- #14. Find out the top 5 states where the order delivery is really fast as
-- #compared to the estimated date of delivery.
-- #You can use the difference between the averages of actual & estimated
-- #delivery date to figure out how fast the delivery was for each state.

SELECT
c.customer_state,
ROUND(AVG(DATE_DIFF(DATE(o.order_estimated_delivery_date),DATE(o.order_delivered_customer_date),DAY)),2)
 AS avg_days_early
FROM `target_sql.orders` o
JOIN `target_sql.customers` c
ON o.customer_id = c.customer_id
WHERE o.order_status='delivered'
GROUP BY c.customer_state
ORDER BY avg_days_early DESC
LIMIT 5;

-- #15. Find the month on month no. of orders placed using different payment types.

SELECT
p.payment_type,
EXTRACT(YEAR FROM o.order_purchase_timestamp) AS year,
EXTRACT(month FROM o.order_purchase_timestamp) AS month,
COUNT(o.order_id) AS no_of_orders
FROM `target_sql.orders` AS o 
INNER JOIN `target_sql.payments` AS p
ON o.order_id = p.order_id
GROUP BY p.payment_type, year, month
ORDER BY p.payment_type, year, month;

-- #16. Find the no. of orders placed on the basis of the payment installments that have been paid.

SELECT 
payment_installments, 
COUNT(order_id) AS no_of_orders
FROM `target_sql.payments`
GROUP BY payment_installments
ORDER BY payment_installments
