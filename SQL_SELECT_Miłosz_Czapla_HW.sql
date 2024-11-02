--1. all animation movies released between 2017 and 2019 with rate more than 1, alphabetical
--part 1: write sql queries to retrieve the following data
--all animation movies released between 2017 and 2019 with rate more than 1, alphabetical
--I will take title of films from film table and filter them by relese date(between 2017 and 2019) and rental_rate higier than 1,
--in order to get films that are animations I need to filter films by category which is is another table - some connection is needed(JOIN or subquery in WHERE)
--and the end i will sort it alphabetical on title
--CTE solution
WITH cte_film_categories AS (
	SELECT
		fc.film_id,
		c.name AS category_name
	FROM
		category c
		INNER JOIN film_category fc ON fc.category_id = c.category_id
)
SELECT
	f.title
FROM
	film f
	INNER JOIN cte_film_categories cfc ON cfc.film_id = f.film_id
WHERE
	f.release_year BETWEEN 2017
	AND 2019
	AND rental_rate > 1
	AND lower(cfc.category_name) = 'animation'
ORDER BY
	f.title ASC;

--With subquries
SELECT
	f.title
FROM
	film f
WHERE
	f.release_year BETWEEN 2017
	AND 2019
	AND rental_rate > 1
	AND f.film_id IN --there is IN bacause is easier to understand than exists
	(
		SELECT
			fc.film_id
		FROM
			category c
			INNER JOIN film_category fc ON fc.category_id = c.category_id
		WHERE
			lower(c.name) = 'animation'
	)
ORDER BY
	f.title ASC;

----the revenue earned by each rental store since march 2017 (columns: address and address2 – as one column, revenue)
--The query uses multiple INNER JOINs to link tables: store, inventory, rental, payment, and address, 
--allowing access to payment data filtered by date and corresponding store locations.
--to calculate revenue per store location since march 2017
SELECT
	sum(p.amount) AS revenue,
	concat(a.address, a.address2) AS address
FROM
	store s
	INNER JOIN inventory i ON i.store_id = s.store_id
	INNER JOIN rental r ON r.inventory_id = i.inventory_id
	INNER JOIN payment p ON p.rental_id = r.rental_id a.address_id = s.address_id --get stores addresses
WHERE
	p.payment_date > '01.03.2017' --filter
GROUP BY
	s.store_id,
	address,
	address2;

--top-5 actors by number of movies (released since 2015) they took part in (columns: first_name, last_name, number_of_movies, sorted by number_of_movies in descending order)
--we need to take table with actor, from which we got first name and last name. But for information about in how many films actors play we need to create relation with film
--table, because it is many to many relation we use middleman table, we filter release date of films, and then count them.
--CTE solution
WITH cte_number_of_films_per_actor_since_2015 AS (
	SELECT
		fa.actor_id,
		count(fa.film_id) AS number_of_movies
	FROM
		film f
		INNER JOIN film_actor fa ON f.film_id = fa.film_id
	WHERE
		f.release_year > 2015
	GROUP BY
		fa.actor_id
	ORDER BY
		number_of_movies DESC
	LIMIT
		5
)
SELECT
	first_name,
	last_name,
	cfa.number_of_movies
FROM
	actor a
	INNER JOIN cte_number_of_films_per_actor_since_2015 cfa ON cfa.actor_id = a.actor_id;

--Subquery solution
SELECT
	first_name,
	last_name,
	count(filmact.*) AS number_of_movies
FROM
	actor a2
	INNER JOIN (
		SELECT
			fa.actor_id
		FROM
			film f
			INNER JOIN film_actor fa ON fa.film_id = f.film_id
		WHERE
			f.release_year > 2015
	) AS filmact ON filmact.actor_id = a2.actor_id
GROUP BY
	a2.actor_id
ORDER BY
	number_of_movies DESC
LIMIT
	5;

--
--number of drama, travel, documentary per year (columns: release_year, number_of_drama_movies, number_of_travel_movies, number_of_documentary_movies), sorted by release year in descending order. dealing with null values is encouraged)
--we take films, use category table to find it category, bacause it is many to many relation we use middleman table to connet those two. We want to see how many drama, travel 
--and documentary movies were released per year so we group output by release year and start counting to do that in one table we use case to check for which category each film
--belongs to and count it only for that category result is shown from the most recent year to furthest from now. Inner join take care for problems with missing data, or null data.
SELECT
	release_year,
	count(
		CASE
			WHEN lower(c.name) = 'drama' THEN 1
		END
	) AS number_of_drama_movies,
	count(
		CASE
			WHEN lower(c.name) = 'travel' THEN 1
		END
	) AS number_of_travel_movies,
	count(
		CASE
			WHEN lower(c.name) = 'documentary' THEN 1
		END
	) AS number_of_documentary_movies
FROM
	film f
	INNER JOIN film_category fc ON fc.film_id = f.film_id
	INNER JOIN category c ON c.category_id = fc.category_id
GROUP BY
	f.release_year
ORDER BY
	f.release_year DESC;

--For each client, display a list of horrors that he had ever rented (IN one COLUMN, separated by commas),
--AND the amount of money that he paid FOR it
--our starting point is client(customer table), from with we need to get information about films client rented, and how much client paid for them to get that information we need to 
--create relation between customer, film and payment rental tables, we use joins to get related data. Besides that we are interested only in horrors so we need to get 
--film category so also need to create relation between film and category table. We use string_agg to show all film specific client bought in one cell.
SELECT
	c.customer_id,
	c.first_name,
	c.last_name,
	string_agg(DISTINCT f.title, ',') AS horror_movies,
	sum(p.amount) AS total_paid
FROM
	customer c
	LEFT JOIN rental r ON c.customer_id = r.customer_id
	LEFT JOIN inventory i ON i.inventory_id = r.inventory_id
	LEFT JOIN payment p ON r.rental_id = p.rental_id
	INNER JOIN film f ON f.film_id = i.film_id
	INNER JOIN film_category fc ON fc.film_id = f.film_id
	LEFT JOIN category c2 ON fc.category_id = c2.category_id
WHERE
	lower(c2.name) = 'horror'
GROUP BY
	c.customer_id;

--
--part 2: solve the following problems using sql
--
--1. which three employees generated the most revenue in 2017? they should be awarded a bonus for their outstanding performance. 
--assumptions: 
--staff could work in several stores in a year, please indicate which store the staff worked in (the last one);
--if staff processed the payment then he works in the same store; 
--take into account only payment_date
--staff can works several stores but it seems that in tables only last id is visible so it is my assumption that I make for results.
--The INNER JOIN approach ensures we capture only active, revenue-generating staff, with payment_date filtering isolating transactions to 2017 only. Inner join assures
--that revenue is calculated per staff for specific store, so it doesn't sum between stores.
SELECT
	s.staff_id,
	s.first_name,
	s.last_name,
	sum(p.amount) AS revenue,
	s2.store_id AS last_store
FROM
	staff s
	INNER JOIN store s2 ON s2.store_id = s.store_id
	INNER JOIN inventory i ON i.store_id = s2.store_id
	INNER JOIN rental r ON r.staff_id = s.staff_id
	INNER JOIN payment p ON p.rental_id = r.rental_id
WHERE
	extract(
		year
		FROM
			p.payment_date
	) = 2017
GROUP BY
	s.staff_id
ORDER BY
	revenue DESC
LIMIT
	3;

--2. which 5 movies were rented more than others (number of rentals), and what's the expected age of the audience for these movies? to determine expected age please use 'motion picture association film rating system
--first we want to get possible rating of filnms
SELECT
	DISTINCT f.rating
FROM
	film f;

----then we use film and joined inventory and rental tables to gather information how many each film were rented.
----To find out what are potential age range that rented specific movie we use case expression. At the end we are asked for only 5 moview with the most rentals, so we need to
----sort them by rental count descending and take 5
SELECT
	f.title,
	count(r.rental_id) AS rental_count,
	CASE
		--case to translate film rating to age
		WHEN f.rating = 'G' THEN 'all ages'
		WHEN f.rating = 'PG' THEN '10+'
		WHEN f.rating = 'PG-13' THEN '13+'
		WHEN f.rating = 'R' THEN '17+'
		WHEN f.rating = 'NC-17' THEN '18+'
		ELSE 'unknown'
	END AS expected_age
FROM
	film f
	INNER JOIN inventory i ON f.film_id = i.film_id
	INNER JOIN rental r ON i.inventory_id = r.inventory_id
GROUP BY
	f.film_id
ORDER BY
	rental_count DESC
LIMIT
	5;

--part 3. which actors/actresses didn't act for a longer period of time than the others? 
--the task can be interpreted in various ways, and here are a few options:
--v1: gap between the latest release_year and current year per each actor;
--We need information about when actor last time played in a film, so we take actors and films tables to get that information, then by substraction from current date we 
--get how long is actor "retired" in years, finnaly lets show only actors who are the most amount of years out of the scene
WITH cte_retired_actors AS (
	SELECT
		a.actor_id,
		a.first_name,
		a.last_name,
		extract(
			year
			FROM
				current_date
		) - max(f.release_year) AS year_gap --finiding biggest year gap per actor
	FROM
		actor a
		INNER JOIN film_actor fa ON fa.actor_id = a.actor_id
		INNER JOIN film f ON f.film_id = fa.film_id
	GROUP BY
		a.actor_id
)
SELECT
	cra.actor_id,
	cra.first_name,
	cra.last_name,
	cra.year_gap
FROM
	cte_retired_actors cra
WHERE
	cra.year_gap = (
		SELECT
			max(year_gap)
		FROM
			cte_retired_actors
	);

--sorting descending, from biggest year gap
--v2: gaps between sequential films per each actor;
--
--it would be plus if you could provide a solution for each interpretation
--
--
--note:
--please add comments why you chose a particular way to solve each tasks.
--ids should not be hardcoded
--don't use column number in group by and order by
--specify join types (inner/right/left/cross)
--use code formatting standards
--you cannot use window functions
--we request you test your work before commit it. code should run w/o errors