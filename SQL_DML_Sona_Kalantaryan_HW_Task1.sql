--1
WITH new_movies AS (
    INSERT INTO film (title, description, release_year, language_id, rental_duration, rental_rate, last_update)
    SELECT * FROM (
        VALUES 
            ('Inception', 'A mind-bending thriller about dream infiltration.', 2010, 1, 6, 19.99, CURRENT_DATE),
            ('Sully: Miracle on the Hudson', 'A pilot safely lands a disabled plane on the Hudson River, saving 155 lives.', 2016, 1, 3, 9.99, CURRENT_DATE),
            ('Interstellar', 'A journey through space and time to save humanity.', 2014, 1, 7, 4.99, CURRENT_DATE)
    ) AS v(title, description, release_year, language_id, rental_duration, rental_rate, last_update)
    WHERE NOT EXISTS (
        SELECT * FROM film f WHERE f.title = v.title
    )
    RETURNING film_id, title
),

new_actors AS (
    INSERT INTO actor (first_name, last_name, last_update)
    SELECT * FROM (
        VALUES 
            ('Leonardo', 'DiCaprio', CURRENT_DATE),
            ('Joseph', 'Gordon-Levitt', CURRENT_DATE),
            ('Tom', 'Hardy', CURRENT_DATE),
            ('Tom', 'Hanks', CURRENT_DATE),
            ('Matthew', 'McConaughey', CURRENT_DATE),
            ('Anne', 'Hathaway', CURRENT_DATE)
    ) AS v(first_name, last_name, last_update)
    ON CONFLICT (first_name, last_name) DO NOTHING
    RETURNING actor_id, first_name, last_name
)

INSERT INTO film_actor (actor_id, film_id, last_update)
SELECT a.actor_id, f.film_id, CURRENT_DATE
FROM new_movies f, new_actors a
WHERE NOT EXISTS (
    SELECT * FROM film_actor fa WHERE fa.actor_id = a.actor_id AND fa.film_id = f.film_id
);


INSERT INTO inventory (film_id, store_id, last_update)
SELECT f.film_id, s.store_id, CURRENT_DATE
FROM new_movies f
JOIN store s ON s.store_id = 1 
WHERE NOT EXISTS (
    SELECT * FROM inventory i WHERE i.film_id = f.film_id AND i.store_id = s.store_id
);


WITH selected_customer AS (
    SELECT customer_id FROM customer
    WHERE (SELECT COUNT(*) FROM rental WHERE rental.customer_id = customer.customer_id) >= 43
      AND (SELECT COUNT(*) FROM payment WHERE payment.customer_id = customer.customer_id) >= 43
    LIMIT 1
)
UPDATE customer
SET first_name = 'Sona', last_name = 'Kalantaryan', email = 'sonakalantaryan23@gmail.com', address_id = (
    SELECT address_id FROM address ORDER BY RANDOM() LIMIT 1
), last_update = CURRENT_DATE
WHERE customer_id = (SELECT customer_id FROM selected_customer);


DELETE FROM rental WHERE customer_id = (SELECT customer_id FROM selected_customer);
DELETE FROM payment WHERE customer_id = (SELECT customer_id FROM selected_customer);


WITH rented_movies AS (
    INSERT INTO rental (rental_date, inventory_id, customer_id, return_date, staff_id, last_update)
    SELECT CURRENT_DATE, inventory.inventory_id, customer.customer_id, CURRENT_DATE + INTERVAL 'one_week', 1, CURRENT_DATE
    FROM inventory
    CROSS JOIN selected_customer AS customer
    JOIN film ON film.film_id = inventory.film_id
    WHERE film.title IN ('Inception', 'Sully: Miracle on the Hudson', 'Interstellar')
    RETURNING rental_id, customer_id
)
INSERT INTO payment (customer_id, staff_id, rental_id, amount, payment_date, last_update)
SELECT rented.customer_id, 1, rented.rental_id, film.rental_rate, CURRENT_DATE, CURRENT_DATE
FROM rented_movies AS rented
JOIN rental ON rental.rental_id = rented.rental_id
JOIN inventory ON inventory.inventory_id = rental.inventory_id
JOIN film ON film.film_id = inventory.film_id;



--2
CREATE TABLE table_to_delete AS
SELECT 'veeeeeeery_long_string' || x AS col
FROM generate_series(1,(10^7)::int) x;


SELECT *, pg_size_pretty(total_bytes) AS total,
                 pg_size_pretty(index_bytes) AS INDEX,
                 pg_size_pretty(toast_bytes) AS toast,
                 pg_size_pretty(table_bytes) AS TABLE
FROM ( 
        SELECT *, total_bytes - index_bytes - COALESCE(toast_bytes, 0) AS table_bytes
        FROM (
            SELECT c.oid, nspname AS table_schema, relname AS TABLE_NAME,
                   c.reltuples AS row_estimate,
                   pg_total_relation_size(c.oid) AS total_bytes,
                   pg_indexes_size(c.oid) AS index_bytes,
                   pg_total_relation_size(reltoastrelid) AS toast_bytes
            FROM pg_class c
            LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
            WHERE relkind = 'r'
        ) a
) a
WHERE table_name LIKE '%table_to_delete%';


DELETE FROM table_to_delete
WHERE REPLACE(col, 'veeeeeeery_long_string','')::int % 3 = 0;


EXPLAIN ANALYZE
DELETE FROM table_to_delete
WHERE REPLACE(col, 'veeeeeeery_long_string','')::int % 3 = 0;


SELECT *, pg_size_pretty(total_bytes) AS total,
                 pg_size_pretty(index_bytes) AS INDEX,
                 pg_size_pretty(toast_bytes) AS toast,
                 pg_size_pretty(table_bytes) AS TABLE
FROM ( 
        SELECT *, total_bytes - index_bytes - COALESCE(toast_bytes, 0) AS table_bytes
        FROM (
            SELECT c.oid, nspname AS table_schema, relname AS TABLE_NAME,
                   c.reltuples AS row_estimate,
                   pg_total_relation_size(c.oid) AS total_bytes,
                   pg_indexes_size(c.oid) AS index_bytes,
                   pg_total_relation_size(reltoastrelid) AS toast_bytes
            FROM pg_class c
            LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
            WHERE relkind = 'r'
        ) a
) a
WHERE table_name LIKE '%table_to_delete%';


VACUUM FULL VERBOSE table_to_delete;


SELECT *, pg_size_pretty(total_bytes) AS total,
                 pg_size_pretty(index_bytes) AS INDEX,
                 pg_size_pretty(toast_bytes) AS toast,
                 pg_size_pretty(table_bytes) AS TABLE
FROM ( 
        SELECT *, total_bytes - index_bytes - COALESCE(toast_bytes, 0) AS table_bytes
        FROM (
            SELECT c.oid, nspname AS table_schema, relname AS TABLE_NAME,
                   c.reltuples AS row_estimate,
                   pg_total_relation_size(c.oid) AS total_bytes,
                   pg_indexes_size(c.oid) AS index_bytes,
                   pg_total_relation_size(reltoastrelid) AS toast_bytes
            FROM pg_class c
            LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
            WHERE relkind = 'r'
        ) a
) a
WHERE table_name LIKE '%table_to_delete%';


DROP TABLE table_to_delete;
CREATE TABLE table_to_delete AS
SELECT 'veeeeeeery_long_string' || x AS col
FROM generate_series(1,(10^7)::int) x;



TRUNCATE table_to_delete;


SELECT *, pg_size_pretty(total_bytes) AS total,
                 pg_size_pretty(index_bytes) AS INDEX,
                 pg_size_pretty(toast_bytes) AS toast,
                 pg_size_pretty(table_bytes) AS TABLE
FROM ( 
        SELECT *, total_bytes - index_bytes - COALESCE(toast_bytes, 0) AS table_bytes
        FROM (
            SELECT c.oid, nspname AS table_schema, relname AS TABLE_NAME,
                   c.reltuples AS row_estimate,
                   pg_total_relation_size(c.oid) AS total_bytes,
                   pg_indexes_size(c.oid) AS index_bytes,
                   pg_total_relation_size(reltoastrelid) AS toast_bytes
            FROM pg_class c
            LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
            WHERE relkind = 'r'
        ) a
) a
WHERE table_name LIKE '%table_to_delete%';



/*
Before DELETE Operation:
Table size: 8192 bytes (8KB)
No indexes or TOAST data.

After DELETE Operation:
Table size: 8192 bytes (8 KB)
Index size: 0 bytes
TOAST size: 0 bytes

After VACUUM FULL
Table size: 8192 bytes (8 KB)
Index size: 0 bytes
TOAST size: 0 bytes

After TRUNCATE 
Table size: 8192 bytes (8 KB)
Index size: 0 bytes (No indexes)
TOAST size: 0 bytes (No TOAST data)
*/
