--1
WITH yearly_sales AS (
    SELECT
        co.country_region,
        t.calendar_year,
        ch.channel_desc,
        SUM(s.amount_sold) AS amount_sold
    FROM sh.sales s
    INNER JOIN sh.times t ON s.time_id = t.time_id
    INNER JOIN sh.customers c ON s.cust_id = c.cust_id
    INNER JOIN sh.countries co ON c.country_id = co.country_id
    INNER JOIN sh.channels ch ON s.channel_id = ch.channel_id
    WHERE t.calendar_year BETWEEN 1999 AND 2001
    GROUP BY co.country_region, t.calendar_year, ch.channel_desc
),
channel_total_percent AS (
    SELECT
        ys.*,
        ROUND(100.0 * ys.amount_sold / SUM(ys.amount_sold) OVER (
            PARTITION BY ys.country_region, ys.calendar_year
        ), 2) AS pct_by_channels
    FROM yearly_sales ys
),
with_previous AS (
    SELECT
        ctp.*,
        LAG(ctp.pct_by_channels) OVER (
            PARTITION BY ctp.country_region, ctp.channel_desc
            ORDER BY ctp.calendar_year
        ) AS pct_previous_period
    FROM channel_total_percent ctp
)
SELECT
    country_region,
    calendar_year,
    channel_desc,
    TO_CHAR(amount_sold, '999,999,990') || ' $' AS "AMOUNT_SOLD",
    TO_CHAR(pct_by_channels, '90.00') || ' %' AS "% BY CHANNELS",
    TO_CHAR(pct_previous_period, '90.00') || ' %' AS "% PREVIOUS PERIOD",
    CASE
        WHEN pct_previous_period IS NOT NULL THEN
            TO_CHAR(pct_by_channels - pct_previous_period, 'FM90.00') || ' %'
        ELSE NULL
    END AS "% DIFF"
FROM with_previous
ORDER BY country_region, calendar_year, channel_desc;



--2
WITH base_data AS (
    SELECT
        t.calendar_week_number,
        t.time_id,
        t.day_name,
        s.amount_sold,
        t.calendar_year,
        SUM(s.amount_sold) OVER (
            PARTITION BY t.calendar_week_number ORDER BY t.time_id
        ) AS cum_sum,
        LAG(s.amount_sold) OVER (ORDER BY t.time_id) AS prev_day,
        LEAD(s.amount_sold) OVER (ORDER BY t.time_id) AS next_day
    FROM sh.sales s
    JOIN sh.times t ON s.time_id = t.time_id
    WHERE t.calendar_year = 1999 AND t.calendar_week_number IN (49, 50, 51)
)
SELECT
    calendar_week_number,
    time_id,
    day_name,
    amount_sold AS sales,
    ROUND(cum_sum, 2) AS cum_sum,
    CASE
        WHEN day_name = 'Monday' THEN ROUND((amount_sold + COALESCE(next_day, 0)) / 2.0, 2)
        WHEN day_name = 'Friday' THEN ROUND((COALESCE(prev_day, 0) + amount_sold) / 2.0, 2)
        ELSE ROUND((COALESCE(prev_day, 0) + amount_sold + COALESCE(next_day, 0)) / 3.0, 2)
    END AS centered_3_day_avg
FROM base_data
ORDER BY time_id;




--3
SELECT 
    time_id,
    amount_sold,
    SUM(amount_sold) OVER (
        ORDER BY time_id 
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS sales_last_3_days
FROM sh.sales
ORDER BY time_id;
--ROWS - because I need to look at the exact 3 rows: current row and 2 before it.
--This is good when I just care about position in the table, not the actual date values.


SELECT 
    t.time_id,
    SUM(s.amount_sold) OVER (
        ORDER BY t.time_id 
        RANGE BETWEEN INTERVAL '7' DAY PRECEDING AND CURRENT ROW
    ) AS weekly_sales
FROM sh.sales s
JOIN sh.times t ON s.time_id = t.time_id
ORDER BY t.time_id;
--RANGE -- because I need to look at all sales from the last 7 days up to today.
--This works better than ROWS when dates aren't perfectly continuous and there are for example missing days,
--As it's based on actual date values, not row count.


SELECT 
    prod_id,
    amount_sold,
    RANK() OVER (ORDER BY amount_sold) AS rank,
    SUM(amount_sold) OVER (
        ORDER BY amount_sold
        GROUPS BETWEEN 1 PRECEDING AND CURRENT ROW
    ) AS grouped_sum
FROM sh.sales
ORDER BY amount_sold;
--GROUPS - when you want to work with tied values.
--Summing up sales from this rank group and the one before.
--It treats rows with the same amount_sold as a group, not as individual rows.

