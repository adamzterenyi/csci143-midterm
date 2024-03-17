/* PROBLEM 1:
 *
 * The Office of Foreign Assets Control (OFAC) is the portion of the US government that enforces international sanctions.
 * OFAC is conducting an investigation of the Pagila company to see if you are complying with sanctions against North Korea.
 * Current sanctions limit the amount of money that can be transferred into or out of North Korea to $5000 per year.
 * (You don't have to read the official sanctions documents, but they're available online at <https://home.treasury.gov/policy-issues/financial-sanctions/sanctions-programs-and-country-information/north-korea-sanctions>.)
 * You have been assigned to assist the OFAC auditors.
 *
 * Write a SQL query that:
 * Computes the total revenue from customers in North Korea.
 *
 * NOTE:
 * All payments in the pagila database occurred in 2022,
 * so there is no need to do a breakdown of revenue per year.
 */

SELECT sum(amount) FROM payment
JOIN customer USING (customer_id)
JOIN address USING (address_id)
JOIN city USING (city_id)
JOIN country USING (country_id)
WHERE country IN ('North Korea');


/* PROBLEM 2:
 *
 * Management wants to hire a family-friendly actor to do a commercial,
 * and so they want to know which family-friendly actors generate the most revenue.
 *
 * Write a SQL query that:
 * Lists the first and last names of all actors who have appeared in movies in the "Family" category,
 * but that have never appeared in movies in the "Horror" category.
 * For each actor, you should also list the total amount that customers have paid to rent films that the actor has been in.
 * Order the results so that actors generating the most revenue are at the top.
 */

WITH FamilyActors AS (
    SELECT actor.actor_id, actor.first_name, actor.last_name
    FROM actor
    JOIN film_actor ON actor.actor_id = film_actor.actor_id
    JOIN film ON film_actor.film_id = film.film_id
    JOIN film_category ON film.film_id = film_category.film_id
    JOIN category ON film_category.category_id = category.category_id
    WHERE category.name = 'Family'
    GROUP BY actor.actor_id
),
HorrorActors AS (
    SELECT actor.actor_id
    FROM actor
    JOIN film_actor ON actor.actor_id = film_actor.actor_id
    JOIN film ON film_actor.film_id = film.film_id
    JOIN film_category ON film.film_id = film_category.film_id
    JOIN category ON film_category.category_id = category.category_id
    WHERE category.name = 'Horror'
    GROUP BY actor.actor_id
),
Revenue AS (
    SELECT 
        actor.actor_id, 
        SUM(payment.amount) AS total_revenue
    FROM actor
    JOIN film_actor ON actor.actor_id = film_actor.actor_id
    JOIN film ON film_actor.film_id = film.film_id
    JOIN inventory ON film.film_id = inventory.film_id
    JOIN rental ON inventory.inventory_id = rental.inventory_id
    JOIN payment ON rental.rental_id = payment.rental_id
    GROUP BY actor.actor_id
)
SELECT 
    fa.first_name, 
    fa.last_name, 
    r.total_revenue
FROM FamilyActors fa
JOIN Revenue r ON fa.actor_id = r.actor_id
WHERE fa.actor_id NOT IN (SELECT actor_id FROM HorrorActors)
ORDER BY r.total_revenue DESC;


/* PROBLEM 3:
 *
 * You love the acting in AGENT TRUMAN, but you hate the actor RUSSELL BACALL.
 *
 * Write a SQL query that lists all of the actors who starred in AGENT TRUMAN
 * but have never co-starred with RUSSEL BACALL in any movie.
 */

WITH bacall_films AS (
    SELECT fa.film_id
    FROM film_actor fa
    JOIN actor a ON fa.actor_id = a.actor_id
    WHERE a.first_name = 'RUSSELL' AND a.last_name = 'BACALL'
),
truman_actors AS (
    SELECT fa.actor_id
    FROM film f
    JOIN film_actor fa ON f.film_id = fa.film_id
    WHERE f.title = 'AGENT TRUMAN'
),
excluded_actors AS (
    SELECT DISTINCT fa.actor_id
    FROM film_actor fa
    JOIN bacall_films bf ON fa.film_id = bf.film_id
)
SELECT a.first_name, a.last_name
FROM actor a
WHERE a.actor_id IN (SELECT actor_id FROM truman_actors)
AND a.actor_id NOT IN (SELECT actor_id FROM excluded_actors)
ORDER BY a.first_name, a.last_name;


/* PROBLEM 4:
 *
 * You want to watch a movie tonight.
 * But you're superstitious,
 * and don't want anything to do with the letter 'F'.
 * List the titles of all movies that:
 * 1) do not have the letter 'F' in their title,
 * 2) have no actors with the letter 'F' in their names (first or last),
 * 3) have never been rented by a customer with the letter 'F' in their names (first or last).
 *
 * NOTE:
 * Your results should not contain any duplicate titles.
 */

WITH nofilm AS (
    SELECT DISTINCT film_id
    FROM film
    WHERE title ILIKE '%f%'
),
noactor AS (
    SELECT DISTINCT film_actor.film_id FROM film_actor
    JOIN actor USING (actor_id)
    WHERE actor.first_name ILIKE '%f%' OR actor.last_name ILIKE '%f%'
),
nocustomer AS (
    SELECT DISTINCT film_id FROM film
    JOIN inventory USING (film_id)
    JOIN rental USING (inventory_id)
    JOIN customer USING (customer_id)
    WHERE customer.first_name ILIKE '%f%' OR customer.last_name ILIKE '%f%'
)
SELECT title FROM film
WHERE film.film_id NOT IN (SELECT film_id FROM nofilm)
AND film.film_id NOT IN (SELECT film_id FROM noactor)
AND film.film_id NOT IN (SELECT film_id FROM nocustomer)
ORDER BY film.title;
