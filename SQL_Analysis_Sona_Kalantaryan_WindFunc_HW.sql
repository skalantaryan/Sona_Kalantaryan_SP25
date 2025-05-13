--1
WITH ranked_sales AS (
    SELECT
        ch.channel_desc,
        c.cust_last_name,
        c.cust_first_name,
        SUM(s.amount_sold) AS amount_sold_raw,
        RANK() OVER (PARTITION BY s.channel_id ORDER BY SUM(s.amount_sold) DESC) AS rnk,
        SUM(s.amount_sold) * 100.0 / SUM(SUM(s.amount_sold)) OVER (PARTITION BY s.channel_id) AS sales_pct
    FROM sh.sales s
    INNER JOIN sh.customers c ON s.cust_id = c.cust_id
    INNER JOIN sh.channels ch ON s.channel_id = ch.channel_id
    GROUP BY ch.channel_desc, c.cust_last_name, c.cust_first_name, s.channel_id
)
SELECT
    channel_desc,
    cust_last_name,
    cust_first_name,
    TO_CHAR(amount_sold_raw, '9999990.00') AS amount_sold,
    TO_CHAR(ROUND(sales_pct, 4), '999990.0000') || ' %' AS sales_percentage
FROM ranked_sales
WHERE rnk <= 5
ORDER BY channel_desc, amount_sold_raw DESC;



--2
--Create the 'tablefunc' extension, enabling the use of functions like crosstab for pivoting data
CREATE EXTENSION IF NOT EXISTS tablefunc;
--using crosstab to pivot columns and make the query cleaner
SELECT 
    ct.product_name,
    ct.q1,
    ct.q2,
    ct.q3,
    ct.q4,
    (COALESCE(ct.q1, 0) + COALESCE(ct.q2, 0) + COALESCE(ct.q3, 0) + COALESCE(ct.q4, 0)) AS year_sum
FROM crosstab(
    $$ 
    SELECT 
        p.prod_name, 
        t.calendar_quarter_number::text AS quarter,
        SUM(s.amount_sold) AS amount_sold
    FROM sh.sales s
    INNER JOIN sh.products p ON s.prod_id = p.prod_id
    INNER JOIN sh.times t ON s.time_id = t.time_id
    INNER JOIN sh.customers c ON s.cust_id = c.cust_id
    INNER JOIN sh.countries co ON c.country_id = co.country_id
    WHERE p.prod_category = 'Photo'
      AND co.country_region = 'Asia'
      AND t.calendar_year = 2000
    GROUP BY p.prod_name, t.calendar_quarter_number
    ORDER BY p.prod_name, t.calendar_quarter_number
    $$,
    $$ SELECT '1' UNION ALL SELECT '2' UNION ALL SELECT '3' UNION ALL SELECT '4' $$  --define the quarters
) AS ct(
    product_name TEXT, 
    q1 NUMERIC, 
    q2 NUMERIC, 
    q3 NUMERIC, 
    q4 NUMERIC
)
ORDER BY ct.product_name;


--3
WITH ranked_sales AS (
    SELECT
        s.cust_id,
        s.channel_id,
        t.calendar_year,
        SUM(s.amount_sold) AS total_sales,
		--ranking customers by sales within each channel and year
        RANK() OVER (PARTITION BY s.channel_id, t.calendar_year ORDER BY SUM(s.amount_sold) DESC) AS rank_in_channel_year
    FROM sh.sales s
    INNER JOIN sh.times t ON s.time_id = t.time_id
    WHERE t.calendar_year IN (1998, 1999, 2001)
    GROUP BY s.cust_id, s.channel_id, t.calendar_year
),
top_customers AS (
    SELECT
        rs.cust_id,
        rs.channel_id,
        COUNT(DISTINCT rs.calendar_year) AS years_in_top300
    FROM ranked_sales rs
    WHERE rs.rank_in_channel_year <= 300
    GROUP BY rs.cust_id, rs.channel_id
    HAVING COUNT(DISTINCT rs.calendar_year) = 3 --Only those who are in top 300 in all 3 years
)
SELECT
    ch.channel_desc,
    rs.cust_id,
    c.cust_last_name,
    c.cust_first_name,
    rs.calendar_year,
    TO_CHAR(rs.total_sales, '9999990.00') AS amount_sold
FROM ranked_sales rs
INNER JOIN top_customers ts ON rs.cust_id = ts.cust_id AND rs.channel_id = ts.channel_id
INNER JOIN sh.customers c ON rs.cust_id = c.cust_id
INNER JOIN sh.channels ch ON rs.channel_id = ch.channel_id
WHERE rs.rank_in_channel_year <= 300
ORDER BY
    ch.channel_desc,
    rs.calendar_year,
    rs.total_sales DESC;


--4
SELECT
    t.calendar_month_desc,
    p.prod_category,
	--to_char to make output nicer
    TO_CHAR(SUM(CASE WHEN co.country_region = 'Americas' THEN s.amount_sold ELSE 0 END), '999,999,990') AS "Americas SALES",
    TO_CHAR(SUM(CASE WHEN co.country_region = 'Europe' THEN s.amount_sold ELSE 0 END), '999,999,990') AS "Europe SALES"
FROM sh.sales s
INNER JOIN sh.customers c ON s.cust_id = c.cust_id
INNER JOIN sh.products p ON s.prod_id = p.prod_id
INNER JOIN sh.times t ON s.time_id = t.time_id
INNER JOIN sh.countries co ON c.country_id = co.country_id
WHERE t.calendar_month_desc IN ('2000-01', '2000-02', '2000-03')
GROUP BY
    t.calendar_month_desc,
    p.prod_category
ORDER BY
    t.calendar_month_desc,
    p.prod_category;


