------------------------------------
----CASE STUDY #1: DANNY'S DINER----
------------------------------------

------------SCHEMA SQL--------------

CREATE SCHEMA dannys_diner;
SET search_path = dannys_diner;

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');

-------------------------
---------Solutions-------
-------------------------
/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
SELECT
	s.customer_id,
    SUM(me.price) as total_sales
FROM dannys_diner.sales s
JOIN dannys_diner.menu me
ON me.product_id = s.product_id
GROUP BY s.customer_id
ORDER BY 1

-- 2. How many days has each customer visited the restaurant?
SELECT
	s.customer_id,
    COUNT(DISTINCT(order_date)) as number_of_days
FROM dannys_diner.sales s
GROUP BY 1
ORDER BY 1

-- 3. What was the first item from the menu purchased by each customer?
WITH t1 as(SELECT 
           s.customer_id,
           MIN(order_date) 	fod
           FROM dannys_diner.sales s 
           GROUP BY s.customer_id)
SELECT s.customer_id,  me.product_name
FROM dannys_diner.sales s
 JOIN t1 
ON t1.customer_id = s.customer_id
JOIN dannys_diner.menu me 
ON me.product_id = s.product_id
WHERE order_date = t1.fod 

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT 
	me.product_name,
    COUNT(s.product_id) 
FROM dannys_diner.sales s
JOIN dannys_diner.menu me
ON me.product_id = s.product_id
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1
          

-- 5. Which item was the most popular for each customer?
WITH t1 as (SELECT customer_id,
          me.product_name,
              COUNT(s.product_id) as order_count
          FROM dannys_diner.sales s
          JOIN dannys_diner.menu me
          ON me.product_id = s.product_id
          GROUP BY 1,2
          ORDER BY 1,3 desc),
    t2 as 
(SELECT 
	*,
    DENSE_RANK() OVER(PARTITION BY t1.customer_id ORDER BY t1.order_count DESC) as ranmki
FROM t1)

SELECT customer_id, product_name, order_count
FROM t2 
WHERE ranmki = 1;




-- 6. Which item was purchased first by the customer after they became a member?
WITH t1 as (SELECT * ,
		DENSE_RANK() OVER(Partition by s.customer_id order by order_date) as ranki
      FROM dannys_diner.sales s
      JOIN dannys_diner.members mem
      ON mem.customer_id = s.customer_id
      WHERE s.order_date >= mem.join_date
      ORDER BY order_date)
      
SELECT 
	*,
    me.product_name
FROM t1
JOIN dannys_diner.menu me
ON me.product_id = t1.product_id
WHERE ranki =1

-- 7. Which item was purchased just before the customer became a member?
WITH t1 AS (SELECT 
              s.customer_id, s.product_id,
              DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date DESC) as rank_
          FROM dannys_diner.sales s
          JOIN dannys_diner.members mem 
          ON mem.customer_id = s.customer_id
          WHERE s.order_date <  mem.join_date
          ORDER BY rank_)

SELECT t1.customer_id , me.product_name
FROM t1
JOIN dannys_diner.menu me
ON me.product_id = t1.product_id
WHERE t1.rank_ = 1

-- 8. What is the total items and amount spent for each member before they became a member?
SELECT
	s.customer_id,
    COUNT(DISTINCT s.product_id) as unique_items,
    SUM(me.price) as total_spent
FROM dannys_diner.sales s
JOIN dannys_diner.menu me 
ON me.product_id = s.product_id
JOIN dannys_diner.members mem
ON s.customer_id = mem.customer_id
WHERE s.order_date < mem.join_date
GROUP BY 1

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
WITH t1 as (SELECT 
            	*,
            	(CASE
            	 WHEN s.product_id = 1 THEN 20*me.price ELSE 10*me.price
                 END
           		 ) as pts
       		FROM dannys_diner.sales s
           	JOIN dannys_diner.menu me 
           	ON me.product_id = s.product_id)
            
SELECT 
	t1.customer_id, 
    SUM(t1.pts)
FROM t1 
GROUP BY 1
ORDER BY 2 DESC

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
WITH t1 AS (SELECT *, 
      join_date + 6*INTERVAL'1 day' as valid_date ,
      '2021-01-31' :: date as last_date
   FROM dannys_diner.members AS mem)
   
SELECT 
	s.customer_id,
    SUM(
      CASE
      WHEN s.product_id = 1 THEN  2*10*me.price
      WHEN s.order_date BETWEEN t1.join_date and t1.valid_date THEN  2*10*me.price
      ELSE 10*me.price
      END
    ) as pts
FROM dannys_diner.sales s
JOIN t1 
ON s.customer_id = t1.customer_id
JOIN dannys_diner.menu me 
ON me.product_id = s.product_id
WHERE s.order_date <= t1.last_date
GROUP BY 1
ORDER BY 2  
-------------------------
-----BONUS QUESTIONS-----
-------------------------

--1) Join All The Things

SELECT
    s.customer_id,
    s.order_date,
    me.product_name,
    me.price,
    (
        CASE
        WHEN s.order_date >= mem.join_date THEN 'Y'
        ELSE 'N'
        END
    ) as member_
FROM dannys_diner.sales S
JOIN dannys_diner.menu me
ON me.product_id = s.product_id
LEFT JOIN dannys_diner.members mem
ON s.customer_id = mem.customer_id
ORDER BY 1,2
