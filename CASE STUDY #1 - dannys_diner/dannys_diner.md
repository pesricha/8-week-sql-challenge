---

**Query #1**

    WITH t1 as (SELECT
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
    ORDER BY 1,2)
    
    SELECT 
    	*,
        (
          CASE 
          WHEN member_ = 'Y' THEN DENSE_RANK() OVER(PARTITION BY customer_id, member_ ORDER BY order_date)
          ELSE NULL
          END
        ) as ranking
    FROM t1;

| customer_id | order_date               | product_name | price | member_ | ranking |
| ----------- | ------------------------ | ------------ | ----- | ------- | ------- |
| A           | 2021-01-01T00:00:00.000Z | sushi        | 10    | N       |         |
| A           | 2021-01-01T00:00:00.000Z | curry        | 15    | N       |         |
| A           | 2021-01-07T00:00:00.000Z | curry        | 15    | Y       | 1       |
| A           | 2021-01-10T00:00:00.000Z | ramen        | 12    | Y       | 2       |
| A           | 2021-01-11T00:00:00.000Z | ramen        | 12    | Y       | 3       |
| A           | 2021-01-11T00:00:00.000Z | ramen        | 12    | Y       | 3       |
| B           | 2021-01-01T00:00:00.000Z | curry        | 15    | N       |         |
| B           | 2021-01-02T00:00:00.000Z | curry        | 15    | N       |         |
| B           | 2021-01-04T00:00:00.000Z | sushi        | 10    | N       |         |
| B           | 2021-01-11T00:00:00.000Z | sushi        | 10    | Y       | 1       |
| B           | 2021-01-16T00:00:00.000Z | ramen        | 12    | Y       | 2       |
| B           | 2021-02-01T00:00:00.000Z | ramen        | 12    | Y       | 3       |
| C           | 2021-01-01T00:00:00.000Z | ramen        | 12    | N       |         |
| C           | 2021-01-01T00:00:00.000Z | ramen        | 12    | N       |         |
| C           | 2021-01-07T00:00:00.000Z | ramen        | 12    | N       |         |

---

[View on DB Fiddle](https://www.db-fiddle.com/f/2rM8RAnq7h5LLDTzZiRWcd/138)
