--1
--know how much each region contributed to each channel’s total sales
WITH regional_sales AS (
    SELECT
        c.channel_desc,
        co.country_region,
        SUM(s.quantity_sold) AS sales
    FROM sh.sales s
    INNER JOIN sh.channels c ON s.channel_id = c.channel_id
    INNER JOIN sh.customers cu ON s.cust_id = cu.cust_id
    INNER JOIN sh.countries co ON cu.country_id = co.country_id
    GROUP BY c.channel_desc, co.country_region
),
--compute the sales percentage contribution by each region within a channel
sales_with_total AS (
    SELECT
        channel_desc,
        country_region,
        ROUND(sales::numeric, 2) AS sales,
        SUM(sales) OVER (PARTITION BY channel_desc) AS total_channel_sales
    FROM regional_sales
),
--match required output format (sales, percentage, region, channel)
final_output AS (
    SELECT
        channel_desc,
        country_region,
        sales,
        ROUND((sales / total_channel_sales) * 100, 2)::text || '%' AS "SALES %"
    FROM sales_with_total
)
--output the data in desired order
SELECT *
FROM final_output
ORDER BY sales DESC;







--2
--need a time series of sales to compare each year's performance
WITH yearly_sales AS (
    SELECT
        t.calendar_year,
        p.prod_subcategory,
        SUM(s.amount_sold) AS sales
    FROM sh.sales s
    JOIN sh.products p ON s.prod_id = p.prod_id
    JOIN sh.times t ON s.time_id = t.time_id
    WHERE t.calendar_year BETWEEN 1998 AND 2001
    GROUP BY t.calendar_year, p.prod_subcategory
),
--year-over-year comparison for each subcategory
lagged_sales AS (
    SELECT
        calendar_year,
        prod_subcategory,
        sales,
        LAG(sales, 1) OVER (PARTITION BY prod_subcategory ORDER BY calendar_year) AS prev_year_sales
    FROM yearly_sales
),
--identify and later filter subcategories that grew consistently
growth_check AS (
    SELECT
        prod_subcategory,
        calendar_year,
        CASE
            WHEN prev_year_sales IS NOT NULL AND sales > prev_year_sales THEN 1
            WHEN prev_year_sales IS NOT NULL THEN 0
            ELSE NULL
        END AS sales_increased
    FROM lagged_sales
),
--want only those that increased in all 3 year-to-year transitions
subcat_growth_summary AS (
    SELECT
        prod_subcategory,
        COUNT(*) FILTER (WHERE sales_increased = 1) AS years_increased,
        COUNT(*) FILTER (WHERE sales_increased IS NOT NULL) AS total_years_compared
    FROM growth_check
    GROUP BY prod_subcategory
)
--filter for subcategories with consistent increases (3 out of 3 comparisons)
SELECT prod_subcategory
FROM subcat_growth_summary
WHERE years_increased = total_years_compared AND total_years_compared = 3;  -- Must increase in all 3 year-to-year comparisons



--3
--narrow down data to only what is relevant to the analysis
WITH filtered_sales AS (
    SELECT
        t.calendar_year,
        t.calendar_quarter_desc,
        p.prod_category,
        s.amount_sold
    FROM sh.sales s
    JOIN sh.products p ON s.prod_id = p.prod_id
    JOIN sh.times t ON s.time_id = t.time_id
    JOIN sh.channels c ON s.channel_id = c.channel_id
    WHERE t.calendar_year IN (1999, 2000)
      AND p.prod_category IN ('Electronics', 'Hardware', 'Software/Other')
      AND c.channel_desc IN ('Internet', 'Partners')
),
--need quarter-level totals to analyze seasonal trends and compare against Q1
quarterly_sales AS (
    SELECT
        calendar_year,
        calendar_quarter_desc,
        prod_category,
        ROUND(SUM(amount_sold), 2) AS sales
    FROM filtered_sales
    GROUP BY calendar_year, calendar_quarter_desc, prod_category
),
--calculate % difference from Q1 and running total (cumulative sum)
sales_with_metrics AS (
    SELECT
        calendar_year,
        calendar_quarter_desc,
        prod_category,
        sales AS "sales$",
        FIRST_VALUE(sales) OVER (
            PARTITION BY calendar_year, prod_category ORDER BY calendar_quarter_desc
        ) AS q1_sales,
        SUM(sales) OVER (
            PARTITION BY calendar_year, prod_category ORDER BY calendar_quarter_desc
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cum_sum
    FROM quarterly_sales
)
--format output columns, including % difference and cumulative sum and sort for readibility
SELECT
    calendar_year,
    calendar_quarter_desc,
    prod_category ,
    ROUND("sales$", 2) AS "sales$",
    CASE 
        WHEN calendar_quarter_desc LIKE '%01' THEN 'N/A'
        ELSE ROUND((("sales$" - q1_sales) / q1_sales) * 100, 2)::TEXT || '%'
    END AS "diff_percent",
    ROUND(cum_sum, 2) AS "cum_sum$"
FROM sales_with_metrics
ORDER BY calendar_year, calendar_quarter_desc, "sales$" DESC;
