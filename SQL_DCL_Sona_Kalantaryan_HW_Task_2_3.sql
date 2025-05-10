--2
--Create a new user and a password for it
CREATE USER rentaluser WITH PASSWORD 'rentalpassword';

--Grant acces to the new user so that he can connect to dvdrental database
GRANT CONNECT ON DATABASE dvdrental TO rentaluser;

--Grant SELECT Privilige to the new user on customer table
GRANT SELECT ON customer TO rentaluser;

--Run this as rentaluser and see if the privilige was granted
SET ROLE rentaluser --Set the role rentaluser
SELECT current_user; --Check if the current user has changed
SELECT * FROM customer;

SET ROLE postgres --Change back the user 

--Create a new user 
CREATE ROLE rental;

--Add rentaluser to the group
GRANT rental TO rentaluser;

--Grant insert, update priviliges to the rental user on rental table
GRANT INSERT, UPDATE ON public.rental TO rental;

--Insert data to rental table as rantal user
GRANT SELECT ON rental TO rental; --grant select privilige to be able to get the id-s correctly
SET ROLE rental; --Set the role rental
SELECT current_user; --Check if the current user has changed
INSERT INTO rental (rental_id, rental_date, inventory_id, customer_id, return_date, staff_id) 
VALUES ((SELECT MAX(rental_id) FROM rental) + 1, CURRENT_DATE, (SELECT inventory_id FROM rental WHERE rental_id = 1000), (SELECT customer_id FROM rental WHERE rental_id = 1000), CURRENT_DATE, (SELECT staff_id FROM rental WHERE rental_id = 1000));
SELECT MAX(rental_id) FROM rental; --get the id of the newly inserted row
UPDATE rental SET return_date = '2025-05-05' WHERE rental_id = 32310;

--Revoke Insert on rental from user rental
REVOKE INSERT ON rental FROM rental;

--try inserting data from rental user after revoking insert privilige 
INSERT INTO rental (rental_id, rental_date, inventory_id, customer_id, return_date, staff_id) 
VALUES ((SELECT MAX(rental_id) FROM rental) + 1, CURRENT_DATE, (SELECT inventory_id FROM rental WHERE rental_id = 1000), (SELECT customer_id FROM rental WHERE rental_id = 1000), CURRENT_DATE, (SELECT staff_id FROM rental WHERE rental_id = 1000));

SET ROLE postgres;

--Choose a customer
SELECT c.customer_id, c.first_name, c.last_name
FROM customer c
JOIN rental r ON c.customer_id = r.customer_id
JOIN payment p ON c.customer_id = p.customer_id
WHERE c.first_name = 'ELIZABETH' AND c.last_name = 'BROWN'
LIMIT 1;

--Create the role
CREATE ROLE client_Elizabeth_Brown;

--Grant SELECT permission on rental and payment tables
GRANT SELECT ON rental TO client_Elizabeth_Brown;
GRANT SELECT ON payment TO client_Elizabeth_Brown;

--3
--Enable Row-Level Security for rental and payment tables
ALTER TABLE rental ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment ENABLE ROW LEVEL SECURITY;

--Create policy for rental table
CREATE POLICY rental_policy ON rental
FOR SELECT USING (customer_id = 5)--(SELECT customer_id FROM customer WHERE first_name = 'Elizabeth' AND last_name = 'Brown'));

--Create policy for payment table
CREATE POLICY payment_policy ON payment
FOR SELECT USING (customer_id = 5)--(SELECT customer_id FROM customer WHERE first_name = 'ELIZABETH' AND last_name = 'BROWN'));

--Set role to test
SET ROLE client_Elizabeth_Brown;

--Try to access rental and payment data
SELECT * FROM rental;
SELECT * FROM payment;

--Revert back to the original role
RESET ROLE;

