-- 1. how many rolls were ordered?

select count(roll_id) from customer_orders;


-- 2. how many unique customer orders were made ?

select count(distinct customer_id) from customer_orders;


-- 3. how many sucessful orders were delivered by each driver

select driver_id ,count(distinct order_id) 
from driver_order
where cancellation not in ('cancellation', 'customer cancellation')
group by driver_id;


-- 4. how many each type of roll was delivered?

SELECT ro.roll_id, ro.roll_name, COUNT(co.roll_id) as roll_count
FROM customer_orders AS co
JOIN driver_order AS do ON do.order_id = co.order_id
JOIN rolls AS ro ON ro.roll_id = co.roll_id
WHERE do.cancellation NOT IN ('Cancellation', 'Customer Cancellation')
GROUP BY ro.roll_id, ro.roll_name;


-- 5. how many veg and non veg rolls were ordered by each cutomer

select customer_id, roll_id, count(roll_id)
from customer_orders
group by 1,2
order by roll_id, customer_id; 

-- 6. what was the maximum number of rolls delivered in a single order

select * from
(
select*,rank() over(order by cnt desc) rnk from
(
select order_id,count(roll_id) cnt
from (
select * from customer_orders where order_id in (
select order_id from
(select *,case when cancellation in ('Cancellation', 'Customer Cancellation') then 'c' else 'nc' end as order_cancel_details
from driver_order)a
where order_cancel_details = 'nc'))b
order by order_id
)c)d where rnk = 1;


-- 7. For each Customer , how many delivered rolls had at least 1 change and how many had no change ?

WITH temp_customer_orders (order_id, customer_id, roll_id, not_include_item, extra_items_included, order_date) AS (
    SELECT
        order_id,
        customer_id,
        roll_id,
        CASE
            WHEN not_include_items IS NULL OR not_include_items = '' THEN 0
            ELSE not_include_items
        END AS not_include_item,
        CASE
            WHEN extra_items_included IS NULL OR extra_items_included = '' OR extra_items_included = 'NaN' OR extra_items_included = 'NULL' THEN '0'
            ELSE extra_items_included
        END AS extra_items_included,
        order_date
    FROM
        customer_orders
),
temp_driver_order (order_id, new_cancellation) AS (
    SELECT
        order_id,
        CASE
            WHEN cancellation IN ('Cancellation', 'Customer Cancellation') THEN 0
            ELSE 1
        END AS new_cancellation
    FROM
        driver_order
)
SELECT
    customer_id,
    chg_no_chg,
    COUNT(order_id) as order_count
FROM
    (
        SELECT
            a.*,
            CASE
                WHEN not_include_item = '0' AND extra_items_included = '0' THEN 'no change'
                ELSE 'change'
            END AS chg_no_chg
        FROM
            temp_customer_orders a
        WHERE
            order_id IN (SELECT order_id FROM temp_driver_order WHERE new_cancellation != 0)
    ) a
GROUP BY customer_id, chg_no_chg;
    

-- 8. how many rolls were delivered that had both exclusions and extras ?

WITH temp_customer_orders (order_id, customer_id, roll_id, not_include_item, extra_items_included, order_date) AS (
    SELECT
        order_id,
        customer_id,
        roll_id,
        CASE
            WHEN not_include_items IS NULL OR not_include_items = '' THEN 0
            ELSE not_include_items
        END AS not_include_item,
        CASE
            WHEN extra_items_included IS NULL OR extra_items_included = '' OR extra_items_included = 'NaN' OR extra_items_included = 'NULL' THEN '0'
            ELSE extra_items_included
        END AS extra_items_included,
        order_date
    FROM
        customer_orders
),
temp_driver_order (order_id, new_cancellation) AS (
    SELECT
        order_id,
        CASE
            WHEN cancellation IN ('Cancellation', 'Customer Cancellation') THEN 0
            ELSE 1
        END AS new_cancellation
    FROM
        driver_order
)
SELECT
    chg_no_chg,
    COUNT(chg_no_chg) as order_count
FROM
    (
        SELECT
            a.*,
            CASE
                WHEN not_include_item != '0' AND extra_items_included != '0' THEN 'both inc exc'
                ELSE 'either 1 inc or exc'
            END AS chg_no_chg
        FROM
            temp_customer_orders a
        WHERE
            order_id IN (SELECT order_id FROM temp_driver_order WHERE new_cancellation != 0)
    ) a
GROUP BY
     chg_no_chg;
     

-- 9. what was the total number of rolls ordered for each hour of the day?

select
hours_bucket, count(hours_bucket) from
(SELECT *,
       CONCAT(EXTRACT(HOUR FROM order_date), '-', EXTRACT(HOUR FROM order_date) + 1) AS hours_bucket
FROM customer_orders)a 
group by hours_bucket
order by count(hours_bucket);


-- 10. what was the number of orders for each day of the week?

select
DOW, count(DOW) order_by_days from
(SELECT *,
       DAYNAME(order_date) as DOW
FROM customer_orders)a 
group by DOW;















