--1-1
SELECT f.title, f.release_year, f.rating
FROM public.film f
JOIN public.film_category fc ON f.film_id = fc.film_id
JOIN public.category c ON fc.category_id = c.category_id
WHERE c.name = 'Animation'
AND f.release_year BETWEEN 2017 AND 2019
AND f.rating IN ('G', 'PG', 'PG-13', 'R')
ORDER BY f.title ASC;

--1-2
SELECT a.address || a.address2 AS full_address,
       SUM(p.amount) AS revenue
FROM public.store s
JOIN public.address a ON s.address_id = a.address_id
JOIN public.inventory i ON s.store_id = i.store_id
JOIN public.rental r ON i.inventory_id = r.inventory_id
JOIN public.payment p ON r.rental_id = p.rental_id
WHERE r.rental_date > '2017-03-31'
GROUP BY a.address, a.address2
ORDER BY revenue DESC;

--1-3
SELECT a.first_name, a.last_name, COUNT(f.film_id) AS number_of_movies
FROM public.actor a
JOIN public.film_actor fa ON a.actor_id = fa.actor_id
JOIN public.film f ON fa.film_id = f.film_id
WHERE f.release_year > 2015
GROUP BY a.actor_id, a.first_name, a.last_name
ORDER BY number_of_movies DESC
LIMIT 5;

--1-4
SELECT f.release_year,
       COUNT(CASE WHEN c.name = 'Drama' THEN f.film_id END) AS number_of_drama_movies,
       COUNT(CASE WHEN c.name = 'Travel' THEN f.film_id END) AS number_of_travel_movies,
       COUNT(CASE WHEN c.name = 'Documentary' THEN f.film_id END) AS number_of_documentary_movies
FROM public.film f
JOIN public.film_category fc ON f.film_id = fc.film_id
JOIN public.category c ON fc.category_id = c.category_id
GROUP BY f.release_year
ORDER BY f.release_year DESC;


--2-1
WITH employee_revenue AS (
    SELECT s.staff_id,
           s.store_id,
           SUM(p.amount) AS total_revenue,
           MAX(p.payment_date) AS last_payment_date
    FROM public.staff s
    JOIN public.payment p ON s.staff_id = p.staff_id
    JOIN public.rental r ON p.rental_id = r.rental_id
    WHERE EXTRACT(YEAR FROM p.payment_date) = 2017
    GROUP BY s.staff_id, s.store_id
),
top_employees AS (
    SELECT staff_id, store_id, total_revenue,
           ROW_NUMBER() OVER (PARTITION BY staff_id ORDER BY last_payment_date DESC) AS store_rank
    FROM employee_revenue
)
SELECT e.first_name, e.last_name, te.total_revenue
FROM top_employees te
JOIN public.staff e ON te.staff_id = e.staff_id
JOIN public.store s ON te.store_id = s.store_id
WHERE te.store_rank = 1  -- Take the last store where the employee worked
ORDER BY te.total_revenue DESC
LIMIT 3;

--2-2
WITH movie_rentals AS (
    SELECT f.film_id, f.title, COUNT(r.rental_id) AS rental_count, f.rating
    FROM public.film f
    JOIN public.inventory i ON f.film_id = i.film_id
    JOIN public.rental r ON i.inventory_id = r.inventory_id
    GROUP BY f.film_id, f.title, f.rating
)
SELECT mr.title, mr.rental_count,
       CASE 
           WHEN mr.rating = 'G' THEN 'All ages'
           WHEN mr.rating = 'PG' THEN 'Children under 13'
           WHEN mr.rating = 'PG-13' THEN 'Children under 13'
           WHEN mr.rating = 'R' THEN 'Under 17 requires parent'
           WHEN mr.rating = 'NC-17' THEN 'No one under 17'
           ELSE 'Unknown'
       END AS expected_audience_age
FROM movie_rentals mr
ORDER BY mr.rental_count DESC
LIMIT 5;

--3-1
SELECT a.first_name, a.last_name,
       EXTRACT(YEAR FROM CURRENT_DATE) - MAX(f.release_year) AS years_since_last_movie
FROM public.actor a
JOIN public.film_actor fa ON a.actor_id = fa.actor_id
JOIN public.film f ON fa.film_id = f.film_id
GROUP BY a.actor_id, a.first_name, a.last_name
ORDER BY years_since_last_movie DESC;

--3-2
WITH movie_gaps AS (
    SELECT a.first_name, a.last_name, f.release_year,
           LEAD(f.release_year) OVER (PARTITION BY a.actor_id ORDER BY f.release_year) AS next_release_year
    FROM public.actor a
    JOIN public.film_actor fa ON a.actor_id = fa.actor_id
    JOIN public.film f ON fa.film_id = f.film_id
)
SELECT first_name, last_name, release_year,
       (next_release_year - release_year) AS gap_between_films
FROM movie_gaps
WHERE next_release_year IS NOT NULL
ORDER BY gap_between_films DESC;







