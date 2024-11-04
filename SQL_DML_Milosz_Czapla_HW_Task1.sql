--Task 1
--Choose your top-3 favorite movies and add them to the 'film' table (films with the title Film1, Film2, etc - will not be taken into account and grade will be reduced)
--The Shawshank Redemption https://en.wikipedia.org/wiki/The_Shawshank_Redemption Tim Robbins, William Sadler,
--Shrek 2 https://en.wikipedia.org/wiki/Shrek_2 Mike Myers, Eddie Murphy, Antonio Banderas, Cameron Diaz
--The Dark Knight https://en.wikipedia.org/wiki/The_Dark_Knight Michael Caine, Morgan Freeman, Aaron Eckhart, Christian Bale
--Fill in rental rates with 4.99, 9.99 and 19.99 and rental durations with 1, 2 and 3 weeks respectively.
INSERT INTO
	film (
		title,
		description,
		release_year,
		original_language_id,
		language_id,
		length,
		rating,
		rental_rate,
		rental_duration
	)
SELECT
	'The Shawshank Redemption',
	'1930s. Andy Dufresne (Tim Robbins) is sentenced to stay in the harshest prison - Shawshank - for the premeditated murder of his wife and her lover. Already on the first night, he becomes convinced of the ruthlessness of the guards, when one of them beats a prisoner to death. Meanwhile, Andy meets Red (Morgan Freeman), whom he becomes friends with. The hero tries not to get in anyone s way until he hears the guards talking about money. Andy, as a banker who knows the tricks of law, helps one of them in financial matters and becomes famous. After a short time, everyone turns to him for help with their taxes. However, the prison warden is not indifferent to his talent and decides to use it to earn money. After some time, a new prisoner appears in Shawshank who could acquit Andy. However, greed wins over the warden, who decides to prevent Dufresne from being released.',
	1994,
	language_id,
	language_id,
	142,
	cast('R' AS mpaa_rating),
	4.99,
	1
FROM
	language l
WHERE
	lower(name) = 'english'
UNION
SELECT
	'Shrek 2',
	'After returning from their honeymoon, Shrek and Fiona decide to visit the princess s parents, who have only received the news of their daughter s wedding to the true love of her life. So the young couple sets off to the kingdom of Transylvania. The problem, however, is that Fiona s parents are not even aware of the curse on her. Therefore, they are sure that she married someone from high society, a bachelor like Lord Farquaad - a ruler ruling a wealthy country. So what a surprise when their son-in-law turns out to be a green ogre weighing over 300 kilograms, who doesn t pay attention to hygiene, and is accompanied by a talking donkey.',
	2004,
	language_id,
	language_id,
	92,
	cast('PG' AS mpaa_rating),
	9.99,
	2
FROM
	language l
WHERE
	lower(name) = 'english'
UNION
SELECT
	'The Dark Knight',
	'In the new film, Batman undertakes a large-scale fight against crime. With the help of Lieutenant Jim Gordon and District Attorney Harvey Dent, he sets out to dismantle existing criminal organizations that plague the city s residents. The cooperation brings results, but the heroes will soon fall victim to the chaos unleashed by a growing criminal genius known to the terrified inhabitants of Gotham as the Joker.',
	2008,
	language_id,
	language_id,
	152,
	cast('PG-13' AS mpaa_rating),
	19.99,
	3
FROM
	language l
WHERE
	lower(name) = 'english' returning film_id;

--
--Add the actors who play leading roles in your favorite movies to the 'actor' and 'film_actor' tables (6 or more actors in total).  Actors with the name Actor1, Actor2, etc - will not be taken into account and grade will be reduced.
-- Dodanie aktorów dla "Shawshank Redemption"
WITH insert_actors_shawshank AS (
	INSERT INTO
		actor (first_name, last_name)
	VALUES
		('Tim', 'Robbins'),
		('William', 'Sadler') returning actor_id
),
-- Dodanie aktorów dla "Shrek 2"
insert_actors_shrek AS (
	INSERT INTO
		actor (first_name, last_name)
	VALUES
		('Mike', 'Myers'),
		('Eddie', 'Murphy'),
		('Antonio', 'Banderas'),
		('Cameron', 'Diaz') returning actor_id
),
-- Dodanie aktorów dla "The Dark Knight"
insert_actors_batman AS (
	INSERT INTO
		actor (first_name, last_name)
	VALUES
		('Michael', 'Caine'),
		('Aaron', 'Eckhart'),
		('Morgan', 'Freeman'),
		('Christian', 'Bale') returning actor_id
) -- Wstawienie danych do tabeli film_actor
INSERT INTO
	film_actor (film_id, actor_id)
SELECT
	(
		SELECT
			f.film_id
		FROM
			film f
		WHERE
			title = 'The Shawshank Redemption'
	) AS film_id,
	actor_id
FROM
	insert_actors_shawshank
UNION
ALL
SELECT
	(
		SELECT
			f.film_id
		FROM
			film f
		WHERE
			title = 'Shrek 2'
	) AS film_id,
	actor_id
FROM
	insert_actors_shrek
UNION
ALL
SELECT
	(
		SELECT
			f.film_id
		FROM
			film f
		WHERE
			title = 'The Dark Knight'
	) AS film_id,
	actor_id
FROM
	insert_actors_batman returning film_id,
	actor_id;

--Add your favorite movies to any store's inventory.
WITH cte_add_fav_mov AS (
	INSERT INTO
		inventory (store_id, film_id)
	SELECT
		1 AS store_id,
		film_id
	FROM
		film f
	WHERE
		f.title IN (
			'The Dark Knight',
			'Shrek 2',
			'The Shawshank Redemption'
		) returning inventory_id
) --check result before commit
SELECT
	s.store_id,
	s.address_id AS store_address,
	f.title
FROM
	inventory i
	INNER JOIN film f ON f.film_id = i.film_id
	INNER JOIN store s ON s.store_id = i.store_id
WHERE
	i.inventory_id IN (
		SELECT
			inventory_id
		FROM
			cte_add_fav_mov
	);

--Alter any existing customer in the database with at least 43 rental and 43 payment records. Change their personal data to yours (first name, last name, address, etc.). You can use any existing address from the "address" table. Please do not perform any updates on the "address" table, as this can impact multiple records with the same address.
WITH cte_update_customer AS (
	UPDATE
		customer cus
	SET
		first_name = 'Miłosz',
		last_name = 'Czapla',
		address_id = 15,
		email = 'notyourbusiness@work.com'
	WHERE
		cus.customer_id = (
			SELECT
				c.customer_id
			FROM
				customer c
			WHERE
				c.customer_id IN (
					SELECT
						p.customer_id
					FROM
						payment p
					GROUP BY
						customer_id
					HAVING
						count(p.*) > 43
				)
				AND c.customer_id IN (
					SELECT
						r.customer_id
					FROM
						rental r
					GROUP BY
						customer_id
					HAVING
						count(r.*) > 43
				)
			LIMIT
				1
		) returning cus.customer_id
) --check result before commit
SELECT
	*
FROM
	customer c
WHERE
	c.customer_id IN (
		SELECT
			customer_id
		FROM
			cte_update_customer
	);

--Remove any records related to you (as a customer) from all tables except 'Customer' and 'Inventory'
--Firstly I used dbveaver to fast look for connections and usage of customer, I looked for customer_id as foreign key, it is preasent in rental and payment tables
--We will use customer_id from the previous task, in my case it was 1. 
--we will perform delete on both tables as CTE to make it at once, otherwise there will be an error because some rental have reference in payment and they cannot be deleted without
--deleting referenced rows in other table 
WITH cte_to_delete_me_rental AS (
	DELETE FROM
		rental
	WHERE
		rental.customer_id = 1 returning *
),
cte_to_delete_me_payment AS (
	DELETE FROM
		payment
	WHERE
		payment.customer_id = 1 returning *
) --check what data would be deleted before commit, check each select one by one so they don't interupt each other
--select * from cte_to_delete_me_rental;
SELECT
	*
FROM
	cte_to_delete_me_payment;

--Rent you favorite movies from the store they are in and pay for them (add corresponding records to the database to represent this activity)
--(Note: to insert the payment_date into the table payment, you can create a new partition (see the scripts to install the training database ) or add records for the
--first half of 2017)
WITH cte_rent_fav AS (
	SELECT
		f.*,
		i.store_id,
		i.inventory_id
	FROM
		film f
		INNER JOIN inventory i ON i.film_id = f.film_id
	WHERE
		f.title IN (
			'The Dark Knight',
			'Shrek 2',
			'The Shawshank Redemption'
		)
)
INSERT INTO
	rental (
		rental_date,
		return_date,
		inventory_id,
		customer_id,
		staff_id
	)
SELECT
	'2017-01-15 10:30:00' :: timestamp,
	'2017-01-15 10:30:00' :: timestamp + (crf.rental_duration * INTERVAL '1 week') AS return_date,
	crf.inventory_id,
	1 AS customer_id,
	1 AS staff_id
FROM
	cte_rent_fav crf RETURNING *;

--Note: 
--All new & updated records must have 'last_update' field set to current_date.
--Double-check your DELETEs and UPDATEs with SELECT query before committing the transaction!!! 
--Your scripts must be rerunnable/reusable and don't produces duplicates. You can use WHERE NOT EXISTS, IF NOT EXISTS, ON CONFLICT DO NOTHING, etc.
--Don't hardcode IDs. Instead of construction INSERT INTO … VALUES use INSERT INTO … SELECT …
--Don't forget to add RETURNING
--Please add comments why you chose a particular way to solve each tasks.
--
--