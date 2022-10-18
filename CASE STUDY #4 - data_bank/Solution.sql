---------------------------------------
-----A. Customer Nodes Exploration-----
---------------------------------------

--1  How many unique nodes are there on the Data Bank system?
        SELECT COUNT(DISTINCT node_id)
        FROM data_bank.customer_nodes
        -- ANS 5

--2  What is the number of nodes per region?
        SELECT 
            region_name as region,
            COUNT(*) as node_count
        FROM data_bank.customer_nodes cn
        JOIN data_bank.regions r
        ON cn.region_id = r.region_id
        GROUP BY 1
        /*| region    | node_count |
        | --------- | ---------- |
        | America   | 735        |
        | Australia | 770        |
        | Africa    | 714        |
        | Asia      | 665        |
        | Europe    | 616        |*/


--3  How many customers are allocated to each region?
        SELECT 
            region_name as region,
            COUNT( customer_id) as customer_count
        FROM data_bank.customer_nodes cn
        JOIN data_bank.regions r
        ON cn.region_id = r.region_id
        GROUP BY 1

        /*
        | region    | customer_count |
        | --------- | -------------- |
        | America   | 735            |
        | Australia | 770            |
        | Africa    | 714            |
        | Asia      | 665            |
        | Europe    | 616            |
        */

--4  How many days on average are customers reallocated to a different node?
        WITH t1 as (SELECT 
            *,
            (end_date - start_date) as day_diff
        FROM data_bank.customer_nodes cn
            WHERE end_date != '9999-12-31' 
                )

        SELECT 
            ROUND(AVG(day_diff), 0) as avg_relocation_days
        FROM t1

        /*
        | avg_relocation_days |
        | ------------------- |
        | 15                  |
        */
--5  What is the median, 80th and 95th percentile for this same reallocation days metric for each region?


---------------------------------------
--------B. Customer Transactions-------
---------------------------------------

--1  What is the unique count and total amount for each transaction type?
        SELECT
            txn_type,
            COUNT(*) as unique_count,
            SUM(txn_amount) as total_amt
        FROM data_bank.customer_transactions
        GROUP BY 1
        /*
        | txn_type   | unique_count | total_amt |
        | ---------- | ------------ | --------- |
        | purchase   | 1617         | 806537    |
        | deposit    | 2671         | 1359168   |
        | withdrawal | 1580         | 793003    |
        */

--2  What is the average total historical deposit counts and amounts for all customers?
        With t1 as
        (
        SELECT
            customer_id,
            COUNT(*) as cnt,
            AVG(txn_amount) sumn
            FROM data_bank.customer_transactions
          WHERE txn_type = 'deposit'
          GROUP BY 1
        )

        SELECT
            AVG(cnt),
            AVG (sumn)
        FROM t1
        /*
        | avg                | avg                  |
        | ------------------ | -------------------- |
        | 5.3420000000000000 | 508.6127820956820957 |
        */

--3  For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
        WITH monthly_transactions AS (
          SELECT 
            customer_id, 
            DATE_PART('month', txn_date) AS month,
            SUM(CASE WHEN txn_type = 'deposit' THEN 0 ELSE 1 END) AS deposit_count,
            SUM(CASE WHEN txn_type = 'purchase' THEN 0 ELSE 1 END) AS purchase_count,
            SUM(CASE WHEN txn_type = 'withdrawal' THEN 1 ELSE 0 END) AS withdrawal_count
          FROM data_bank.customer_transactions
          GROUP BY customer_id, month
        )

        SELECT
          month,
          COUNT(DISTINCT customer_id) AS customer_count
        FROM monthly_transactions
        WHERE deposit_count >= 2 
          AND (purchase_count > 1 OR withdrawal_count > 1)
        GROUP BY month
        ORDER BY month;
        /*
        | month | customer_count |
        | ----- | -------------- |
        | 1     | 158            |
        | 2     | 240            |
        | 3     | 263            |
        | 4     | 86             |
        */

--4  What is the closing balance for each customer at the end of the month?


--5  What is the percentage of customers who increase their closing balance by more than 5%?
