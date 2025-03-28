--1-1
SELECT f.title
FROM public.film f
INNER JOIN public.film_category fc ON f.film_id = fc.film_id 
INNER JOIN public.category c ON fc.category_id = c.category_id
WHERE c.name = 'Animation' --filter based on the film category, choose only Animation
AND f.release_year BETWEEN 2017 AND 2019 --filter based on the release year
AND f.rating IN ('G', 'PG', 'PG-13', 'R') --filter based on the ratings that are higher than 1 - means exclude NC17
ORDER BY f.title ASC;

--1-2
SELECT 
	CASE WHEN a.address is NULL OR a.address2 is NULL THEN a.address || a.address2
		ELSE a.address || ', ' || a.address2 
	END AS full_address,
	--when any of the addresses is null then write them without space or , 
	--if a.address is null it will write only a.address2 and vice vers
	--and if none of them is null - ELSE - then it will write a.address, a.address2
    SUM(p.amount) AS revenue
FROM public.store s
LEFT JOIN public.address a ON s.address_id = a.address_id --LEFT as the store can not have address, but we will still need it
INNER JOIN public.inventory i ON s.store_id = i.store_id --INNER as if the store is not in inventory then it does not have payments
INNER JOIN public.rental r ON i.inventory_id = r.inventory_id --INNER as if the inventory is not in rental it does not have payments
LEFT JOIN public.payment p ON r.rental_id = p.rental_id --LEFT as the rental can not have payments
WHERE EXTRACT(YEAR FROM r.rental_date) = 2017 --the movie was rented in 2017
	AND EXTRACT(MONTH FROM r.rental_date) > 3 --the movie was rented after March
GROUP BY s.store_id, a.address, a.address2
ORDER BY revenue DESC;

--1-3
SELECT a.first_name, a.last_name, COUNT(f.film_id) AS number_of_movies
FROM public.actor a
INNER JOIN public.film_actor fa ON a.actor_id = fa.actor_id 
INNER JOIN public.film f ON fa.film_id = f.film_id
--INNER JOINs are needed as we need count of films from film table of each actor in actor movie
WHERE f.release_year > 2015
GROUP BY a.actor_id, a.first_name, a.last_name
ORDER BY number_of_movies DESC
LIMIT 5;

--1-4
SELECT f.release_year,
       COUNT(CASE WHEN UPPER(c.name) = 'DRAMA' THEN f.film_id END) AS number_of_drama_movies,
       COUNT(CASE WHEN UPPER(c.name) = 'TRAVEL' THEN f.film_id END) AS number_of_travel_movies,
       COUNT(CASE WHEN UPPER(c.name) = 'DOCUMENTARY' THEN f.film_id END) AS number_of_documentary_movies
FROM public.film f
INNER JOIN public.film_category fc ON f.film_id = fc.film_id
INNER JOIN public.category c ON fc.category_id = c.category_id
--INNER JOINs as we need categories of movies, if the movie does not have category we don't need it
GROUP BY f.release_year
ORDER BY f.release_year DESC;


--2-1
WITH employee_revenue AS (
    SELECT s.staff_id,
           s.store_id,
           SUM(p.amount) AS total_revenue,
           MAX(p.payment_date) AS last_payment_date
    FROM public.staff s
    LEFT JOIN public.payment p ON s.staff_id = p.staff_id
	--LEFT JOIN as the staff can not have payment
    INNER JOIN public.rental r ON p.rental_id = r.rental_id
	--INNER JOIN as if the staff doesn not have rental we don't need it 
    WHERE EXTRACT(YEAR FROM p.payment_date) = 2017
    GROUP BY s.staff_id, s.store_id
),--we get the each staff's total amount of revenue in each store
	top_employees AS (
    SELECT staff_id, store_id, total_revenue,
           ROW_NUMBER() OVER (PARTITION BY staff_id ORDER BY last_payment_date DESC) AS store_rank 
		   --This will assign ranks(row numbers) by grouping rows by last_payment_date, 
		   --so that we can choose the last store the staff worked in
    FROM employee_revenue
)--we give rank to each store based on order of working places of each staff
SELECT s.store_id, e.first_name || ' ' || e.last_name, te.total_revenue
FROM top_employees te
INNER JOIN public.staff e ON te.staff_id = e.staff_id
INNER JOIN public.store s ON te.store_id = s.store_id
--INNER JOINs as we need each employee's revenue from each store
WHERE te.store_rank = 1  --choose the last place of work of each employee
ORDER BY te.total_revenue DESC;

--2-2
WITH movie_rentals AS (
    SELECT f.film_id, f.title, COUNT(r.rental_id) AS rental_count, f.rating
    FROM public.film f
    INNER JOIN public.inventory i ON f.film_id = i.film_id
    INNER JOIN public.rental r ON i.inventory_id = r.inventory_id
	--INNER JOINs as we need films that have been rented
    GROUP BY f.film_id, f.title, f.rating
)

SELECT mr.title, mr.rental_count,
       CASE 
           WHEN mr.rating = 'G' THEN 'All ages'
           WHEN mr.rating = 'PG' THEN 'Inappropriate for Children Under 13'
           WHEN mr.rating = 'PG-13' THEN 'Children Under 17 Require Accompanying Adult'
           WHEN mr.rating = 'R' THEN 'Inappropriate for Children Under 17'
           WHEN mr.rating = 'NC-17' THEN 'No one under 17'
           ELSE 'Unknown'
       END AS expected_audience_age
	   --for each rating assign specific text as output
FROM movie_rentals mr
ORDER BY mr.rental_count DESC
LIMIT 5;

--3-1
WITH actor_last_movie AS (
	SELECT a.first_name, a.last_name,
       EXTRACT(YEAR FROM CURRENT_DATE) - MAX(f.release_year) AS years_since_last_movie --get the years since the last movie
	FROM public.actor a
	INNER JOIN public.film_actor fa ON a.actor_id = fa.actor_id
	INNER JOIN public.film f ON fa.film_id = f.film_id
	--LEFT JOINs to get only actors that have acted in a film
	GROUP BY a.actor_id, a.first_name, a.last_name
)	

SELECT * 
FROM actor_last_movie
WHERE years_since_last_movie = (SELECT MAX(years_since_last_movie) FROM actor_last_movie)
ORDER BY first_name, last_name;

--3-2
WITH movie_gaps AS (
    SELECT a.actor_id, a.first_name, a.last_name, f1.release_year AS release_year,
           MIN(f2.release_year) AS next_release_year, --this gets the next movie release year
		   CASE 
		   	WHEN MIN(f2.release_year) IS NULL
			   THEN EXTRACT(YEAR FROM CURRENT_DATE) - f1.release_year
           	ELSE 
			   MIN(f2.release_year) - f1.release_year 
			END AS gap_between_films
			--if there was no next movie then the gap should be calculated till current year
    FROM public.actor a
    INNER JOIN public.film_actor fa1 ON a.actor_id = fa1.actor_id
    INNER JOIN public.film f1 ON fa1.film_id = f1.film_id
	--INNER JOINs to get actors who have acted in a film
    LEFT JOIN public.film_actor fa2 ON a.actor_id = fa2.actor_id
    LEFT JOIN public.film f2 ON fa2.film_id = f2.film_id AND f2.release_year > f1.release_year --we get next movie from release_year 
    --LEFT JOINs to get even those actors that don't have a next movie
	GROUP BY a.actor_id, a.first_name, a.last_name, f1.release_year
	ORDER BY actor_id, first_name, last_name, release_year
)
SELECT first_name, last_name, MAX(gap_between_films) AS longest_gap
FROM movie_gaps
WHERE gap_between_films IS NOT NULL
GROUP BY first_name, last_name
HAVING MAX(gap_between_films) = (SELECT MAX(gap_between_films) FROM movie_gaps) 
--choose the ones that have the largest gap between movies
ORDER BY first_name, last_name;

