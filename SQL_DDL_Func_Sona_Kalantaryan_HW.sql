BEGIN;

--1
CREATE OR REPLACE VIEW sales_revenue_by_category_qtr AS
SELECT 
	c.name AS category,
	SUM(p.amount) AS total_revenue
FROM category c
INNER JOIN film_category fc ON c.category_id = fc.category_id
INNER JOIN film f ON fc.film_id = f.film_id
INNER JOIN inventory i ON f.film_id = i.film_id
INNER JOIN rental r ON i.inventory_id = r.inventory_id
INNER JOIN payment p ON r.rental_id = p.rental_id
WHERE DATE_PART('year', p.payment_date) = DATE_PART('year', CURRENT_DATE) AND --take only the year of p.payment_date and current date
	DATE_PART('quarter', p.payment_date) = DATE_PART('quarter', CURRENT_DATE) --take the quarter based on p.payment_date and current date
GROUP BY c.category_id
HAVING SUM(p.amount) > 0;


--2
CREATE OR REPLACE FUNCTION get_sales_revenue_by_category_qtr (
    quarter_year TEXT  -- for instance '2024-Q1'
)
RETURNS TABLE (
    category TEXT, 
    total_revenue NUMERIC
)
AS $$
DECLARE
    qtr INT;
    yr INT;
BEGIN
	--Check if the input was accurate
	IF quarter_year NOT LIKE '____-Q_' THEN
        RAISE EXCEPTION 'Invalid format: use YYYY-Qn (e.g., 2024-Q1)';
    END IF;
    yr := SPLIT_PART(quarter_year, '-', 1)::INT; --take the YEAR FROM the text parameter
    qtr := RIGHT(quarter_year, 1)::INT; --take the quearter FROM the parameter
    RETURN QUERY
    SELECT 
        c.name AS category,
        SUM(p.amount) AS total_revenue
    FROM category c
    INNER JOIN film_category fc ON c.category_id = fc.category_id
    INNER JOIN film f ON fc.film_id = f.film_id
    INNER JOIN inventory i ON f.film_id = i.film_id
    INNER JOIN rental r ON i.inventory_id = r.inventory_id
    INNER JOIN payment p ON r.rental_id = p.rental_id
    WHERE DATE_PART('year', p.payment_date) = yr
      AND DATE_PART('quarter', p.payment_date) = qtr
    GROUP BY c.category_id
    HAVING SUM(p.amount) > 0;
END;
$$ LANGUAGE plpgsql;


--3
CREATE OR REPLACE FUNCTION get_most_popular_film_by_country(country_names TEXT[])
	RETURNS TABLE(
		country TEXT, 
		film TEXT, 
		rating mpaa_rating, 
		language CHAR(25), 
		length SMALLINT, 
		release_year INT) 
	AS $$
BEGIN
	RETURN QUERY
	SELECT 
		c.country AS country,
		f.title AS film,
		f.rating AS rating,
		l.name AS language,
		f.length AS length,
		f.release_year::integer AS release_year
	FROM film f
	INNER JOIN language l ON f.language_id = l.language_id
	INNER JOIN inventory i ON f.film_id = i.film_id
	INNER JOIN rental r ON i.inventory_id = r.inventory_id
	INNER JOIN customer cm ON r.customer_id = cm.customer_id
	INNER JOIN address a ON cm.address_id = a.address_id
	INNER JOIN city ct ON a.city_id = ct.city_id
	INNER JOIN country c ON ct.country_id = c.country_id
	WHERE c.country = ANY(country_names)
	GROUP BY c.country, f.title, f.rating, l.name, f.length, f.release_year
	HAVING COUNT(r.rental_id) = (
		SELECT MAX(cnt) FROM (
            SELECT COUNT(r2.rental_id) AS cnt
            FROM rental r2
            INNER JOIN inventory i2 ON r2.inventory_id = i2.inventory_id
            INNER JOIN film f2 ON i2.film_id = f2.film_id
            INNER JOIN customer cm2 ON r2.customer_id = cm2.customer_id
            INNER JOIN address a2 ON cm2.address_id = a2.address_id
            INNER JOIN city ct2 ON a2.city_id = ct2.city_id
            INNER JOIN country c2 ON ct2.country_id = c2.country_id
            WHERE c2.country = c.country
            GROUP BY f2.title
        ) AS subquery
	);
END;
$$ LANGUAGE plpgsql;


--4
CREATE OR REPLACE FUNCTION films_in_stock_by_title(title_type TEXT)
	RETURNS TABLE(
		row_num BIGINT, 
		film_title TEXT, 
		language CHAR(25), 
		customer_name TEXT, 
		rental_date timestamp with time zone) 
	AS $$
BEGIN
	RETURN QUERY
	SELECT 
		ROW_NUMBER() OVER (ORDER BY f.title) AS row_num,
		f.title AS film_title,
		l.name AS language,
		c.first_name || c.last_name AS customer_name,
		r.rental_date
	FROM film f
	INNER JOIN language l ON f.language_id = l.language_id
	INNER JOIN inventory i ON f.film_id = i.film_id
	INNER JOIN rental r ON i.inventory_id = r.inventory_id
	INNER JOIN customer c ON r.customer_id = c.customer_id
	WHERE LOWER(f.title) LIKE LOWER(title_type) 
		AND r.return_date IS NOT NULL
		AND r.rental_date = (
			SELECT MAX(r2.rental_date)
			FROM rental r2
			WHERE r2.inventory_id = r.inventory_id
				AND r2.return_date IS NOT NULL
		)
	GROUP BY f.title, l.name, c.first_name || c.last_name, r.rental_date
	HAVING COUNT(i.inventory_id) > 0
	ORDER BY row_num;
	IF NOT FOUND THEN
        RAISE NOTICE 'No movies found for the given title pattern: %', title_type;
    END IF;
END;
$$ LANGUAGE plpgsql;

--5
CREATE OR REPLACE PROCEDURE new_movie(
	title TEXT, 
	release_year INT DEFAULT EXTRACT(YEAR FROM CURRENT_DATE), 
	language_name text DEFAULT 'Klingon')
LANGUAGE plpgsql 
AS $$
DECLARE 
	lang_id INT;
BEGIN
	SELECT language_id INTO lang_id
	FROM language
	WHERE LOWER(name) = LOWER(language_name);

	IF NOT FOUND THEN
    	RAISE EXCEPTION 'Language "%" does not exist in the language table', language_name;
    END IF;

	INSERT INTO film (title, release_year, language_id, rental_rate, rental_duration, replacement_cost)
	VALUES (title, release_year, language_id, 4.99, 3, 19.99);
END;
$$;


/*BEGIN;

CALL new_movie('The Great Adventure', 2024);

ROLLBACK;
*/

COMMIT;
