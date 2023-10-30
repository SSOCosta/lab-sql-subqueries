-- Write SQL queries to perform the following tasks using the Sakila database:

-- 1. Determine the number of copies of the film "Hunchback Impossible" that exist in the inventory system.
USE SAKILA;

SELECT* FROM sakila.film;
SELECT* FROM sakila.inventory;

SELECT f.title AS 'film_title', i.film_id AS 'film_id', COUNT(*) AS 'number_of_copies'
FROM sakila.film AS f
JOIN sakila.inventory AS i USING (film_id)
WHERE f.title = 'Hunchback Impossible'
GROUP BY f.title, i.film_id;

-- or with a subquery

SELECT count(i.film_id) AS number_of_copies
FROM inventory i
WHERE i.film_id = (SELECT f.film_id
				   FROM film f
                   WHERE f.title = "Hunchback Impossible");

-- 2. List all films whose length is longer than the average length of all the films in the Sakila database.

SELECT* FROM sakila.film;
SELECT AVG(length) FROM sakila.film;

SELECT f.title AS 'film_title', f.length AS 'film_length'
FROM sakila.film AS f
WHERE f.length > (SELECT AVG(length) FROM sakila.film)
GROUP BY f.title, f.length
ORDER BY f.length DESC
limit 10;

-- 3. Use a subquery to display all actors who appear in the film "Alone Trip".

SELECT* FROM sakila.actor;
SELECT* FROM sakila.film_actor;

SELECT actor_id, a.first_name, a.last_name
FROM sakila.actor AS a
WHERE a.actor_id IN (SELECT fa.actor_id
						FROM sakila.film_actor AS fa
                        WHERE fa.film_id = (SELECT f.film_id
											FROM sakila.film AS f
                                            WHERE f.title = 'Alone Trip'));


-- BONUS QUESTIONS:

-- 4. Sales have been lagging among young families, and you want to target family movies for a promotion.
-- Identify all movies categorized as family films.

SELECT* FROM sakila.category; -- category ID 8

SELECT f.title, c.category_id
FROM sakila.category AS c
JOIN sakila.film_category AS fc USING (category_id)
JOIN sakila.film AS f USING (film_id)
WHERE c.category_id = 8
GROUP BY f.title, c.category_id
ORDER BY f.title ASC;

-- or using subqueries

SELECT f.title AS title_of_family_film
FROM film f
WHERE f.film_id IN (SELECT fc.film_id
				   FROM film_category fc
				   WHERE fc.category_id = (SELECT c.category_id
										   FROM category c
										   WHERE c.name = 'Family'));

-- 5. Retrieve the name and email of customers from Canada using both subqueries and joins. 
-- To use joins, you will need to identify the relevant tables and their primary and foreign keys.

SELECT* FROM sakila.customer;
SELECT* FROM sakila.country;
SELECT* FROM sakila.address;

SELECT c.first_name, c.last_name, c.email
FROM sakila.customer AS c
JOIN sakila.address AS a USING (address_id)
JOIN sakila.city AS ci	USING (city_id)
JOIN sakila.country AS co USING (country_id)
WHERE co.country = 'Canada';

-- or with subqueries

SELECT c.first_name, c.last_name, c.email
FROM customer c
WHERE c.address_id IN (SELECT a.address_id
						FROM address a
						WHERE a.city_id IN (SELECT ci.city_id
											FROM city ci
											WHERE ci.country_id = (SELECT co.country_id
																   FROM country co
																   WHERE co.country = 'Canada')));

-- 6. Determine which films were starred by the most prolific actor in the Sakila database. 
-- A prolific actor is defined as the actor who has acted in the most number of films. 
-- First, you will need to find the most prolific actor and then use that actor_id to find the different films that he or she starred in.

-- Find the actor_id of the most prolific actor
SELECT ac.actor_id, ac.first_name, ac.last_name, COUNT(fa.actor_id) AS 'film_count'
FROM sakila.actor AS ac
JOIN sakila.film_actor AS fa USING (actor_id)
GROUP BY ac.actor_id, ac.first_name, ac.last_name
ORDER BY film_count DESC
LIMIT 1;

-- Find films starred by the most prolific actor and list the actor's first and last name
SELECT f.film_id, f.title, fa.actor_id
FROM sakila.film AS f
JOIN sakila.film_actor AS fa USING (film_id)
WHERE fa.actor_id = (
    SELECT ac.actor_id
    FROM sakila.actor AS ac
    JOIN sakila.film_actor USING (actor_id)
    GROUP BY ac.actor_id
    ORDER BY COUNT(*) DESC
    LIMIT 1
);

-- 7.Find the films rented by the most profitable customer in the Sakila database. 
-- You can use the customer and payment tables to find the most profitable customer, i.e., the customer who has made 
-- the largest sum of payments.

-- Find the most profitable customer who has made the largest sum of payments
SELECT c.customer_id
FROM sakila.customer AS c
JOIN sakila.payment AS p USING (customer_id)
GROUP BY c.customer_id
ORDER BY SUM(p.amount) DESC
LIMIT 1;

-- Which films were rented by the most profitable customer
SELECT f.film_id, f.title, c.customer_id
FROM sakila.customer AS c
JOIN sakila.rental AS r USING (customer_id)
JOIN sakila.inventory AS i USING (inventory_id)
JOIN sakila.film AS f USING (film_id)
WHERE c.customer_id = (
    SELECT c.customer_id
    FROM sakila.customer AS c
    JOIN sakila.payment AS p USING (customer_id)
    GROUP BY c.customer_id
    ORDER BY SUM(p.amount) DESC
    LIMIT 1
);


-- 8.Retrieve the client_id and the total_amount_spent of those clients who spent more than the average of the total_amount 
-- spent by each client. You can use subqueries to accomplish this.

-- Calculate the average total amount spent by each client
SELECT AVG(total_amount_spent) AS average_total_amount
FROM (
    SELECT c.customer_id, SUM(p.amount) AS total_amount_spent
    FROM sakila.customer AS c
    JOIN sakila.payment AS p USING (customer_id)
    GROUP BY c.customer_id
) AS customer_total_amount;

-- Retrieve client_id and total_amount_spent for clients who spent more than the average
SELECT c.customer_id AS client_id, SUM(p.amount) AS total_amount_spent
FROM sakila.customer AS c
JOIN sakila.payment AS p USING (customer_id) 
GROUP BY c.customer_id
HAVING SUM(p.amount) > (SELECT AVG(total_amount_spent) AS average_total_amount
                       FROM (
                           SELECT c.customer_id, SUM(p.amount) AS total_amount_spent
                           FROM sakila.customer AS c
                           JOIN sakila.payment AS p USING (customer_id)
                           GROUP BY c.customer_id) AS customer_total_amount);
