--Task 1
--Choose your top-3 favorite movies and add them to the 'film' table (films with the title Film1, Film2, etc - will not be taken into account and grade will be reduced)
--I chosee my favorite films: 
--The Shawshank Redemption https://en.wikipedia.org/wiki/The_Shawshank_Redemption Tim Robbins, William Sadler,
--Shrek 2 https://en.wikipedia.org/wiki/Shrek_2 Mike Myers, Eddie Murphy, Antonio Banderas, Cameron Diaz
--The Dark Knight https://en.wikipedia.org/wiki/The_Dark_Knight Michael Caine, Morgan Freeman, Aaron Eckhart, Christian Bale
--Fill in rental rates with 4.99, 9.99 and 19.99 and rental durations with 1, 2 and 3 weeks respectively.
--we use CTE to insert data of all films in one insert with language comming from language table
--I don't add last_update because it's default value it now
BEGIN;

SELECT
	CURRENT_DATE;

savepoint sv_add_films;

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
		rental_duration,
		last_update
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
	7,
	CURRENT_DATE
FROM
	language l
WHERE
	lower(name) = 'english'
	AND NOT EXISTS (
		SELECT
			film_id
		FROM
			film
		WHERE
			title = 'The Shawshank Redemption'
	)
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
	14,
	CURRENT_DATE
FROM
	language l
WHERE
	lower(name) = 'english'
	AND NOT EXISTS (
		SELECT
			film_id
		FROM
			film
		WHERE
			title = 'Shrek 2'
	)
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
	21,
	CURRENT_DATE
FROM
	language l
WHERE
	lower(name) = 'english'
	AND NOT EXISTS (
		SELECT
			film_id
		FROM
			film
		WHERE
			title = 'The Dark Knight'
	) returning *;

--ROLLBACK TO SAVEPOINT sv_add_films; -- if you want rollback uncomment it 
COMMIT;

--
--Add the actors who play leading roles in your favorite movies to the 'actor' and 'film_actor' tables (6 or more actors in total).  Actors with the name Actor1, Actor2, etc - will not be taken into account and grade will be reduced.
-- I searched for actors I know and like from my favorite movies online and added them to actor table in manner of 3 CTE divided by film they played in
--I use returning to get ids of actors from actor table, that I use to connect right actors with right films in insert into film_actor
--I don't add last_update because it's default value it now
--at the end I got information about established connection
BEGIN;

SAVEPOINT sv_add_actors;

WITH insert_actors_shawshank AS (
	INSERT INTO
		actor (first_name, last_name, last_update)
	VALUES
		('Tim', 'Robbins', CURRENT_DATE),
		('William', 'Sadler', CURRENT_DATE) returning actor_id
),
-- add actors to for film  "Shrek 2"
insert_actors_shrek AS (
	INSERT INTO
		actor (first_name, last_name, last_update)
	VALUES
		('Mike', 'Myers', CURRENT_DATE),
		('Eddie', 'Murphy', CURRENT_DATE),
		('Antonio', 'Banderas', CURRENT_DATE),
		('Cameron', 'Diaz', CURRENT_DATE) returning actor_id
),
-- add actors to for film "The Dark Knight"
insert_actors_batman AS (
	INSERT INTO
		actor (first_name, last_name, last_update)
	VALUES
		('Michael', 'Caine', CURRENT_DATE),
		('Aaron', 'Eckhart', CURRENT_DATE),
		('Morgan', 'Freeman', CURRENT_DATE),
		('Christian', 'Bale', CURRENT_DATE) returning actor_id
) -- add connection between film and actor table to table film_actor
--
INSERT INTO
	film_actor (film_id, actor_id, last_update)
SELECT
	f.film_id,
	i.actor_id,
	CURRENT_DATE
FROM
	film f
	INNER JOIN insert_actors_shawshank i ON f.title = 'The Shawshank Redemption'
UNION
ALL
SELECT
	film_id,
	actor_id,
	CURRENT_DATE
FROM
	film
	INNER JOIN insert_actors_shrek ON title = 'Shrek 2'
UNION
ALL
SELECT
	film_id,
	actor_id,
	CURRENT_DATE
FROM
	film
	INNER JOIN insert_actors_batman ON title = 'The Dark Knight' returning film_id,
	actor_id;

--rollback to savepoint sv_add_actors;  -- if you want rollback uncomment it 
COMMIT;

--Add your favorite movies to any store's inventory.
--I used film titles to find it's ids and created CTE to chosee random store, so all moviews will be added to inventory
--of one store at ones
BEGIN;

savepoint sv_add_inventory;

WITH random_store_id AS (
	SELECT
		ceil(random() * max(store_id)) AS store_id
	FROM
		store
),
cte_select_inventory AS (
	SELECT
		i.film_id,
		s.store_id
	FROM
		inventory i
		INNER JOIN film f ON f.film_id = i.film_id
		INNER JOIN store s ON s.store_id = i.store_id
	WHERE
		f.title IN (
			'The Dark Knight',
			'Shrek 2',
			'The Shawshank Redemption'
		)
		AND s.store_id = (
			SELECT
				store_id
			FROM
				random_store_id
		)
)
INSERT INTO
	inventory (store_id, film_id, last_update)
SELECT
	(
		SELECT
			store_id
		FROM
			random_store_id
	) AS store_id,
	film_id,
	CURRENT_DATE
FROM
	film f
WHERE
	f.title IN (
		'The Dark Knight',
		'Shrek 2',
		'The Shawshank Redemption'
	)
	AND NOT EXISTS (
		SELECT
			*
		FROM
			cte_select_inventory
	);

--check result before commit
SELECT
	s.store_id,
	s.address_id AS store_address,
	f.title
FROM
	inventory i
	INNER JOIN film f ON f.film_id = i.film_id
	INNER JOIN store s ON s.store_id = i.store_id
WHERE
	f.title IN (
		'The Dark Knight',
		'Shrek 2',
		'The Shawshank Redemption'
	);

--rollback to savepoint sv_add_inventory; -- if you want rollback uncomment it 
COMMIT;

--Alter any existing customer in the database with at least 43 rental and 43 payment records. Change their personal data to yours (first name, last name, address, etc.). You can use any existing address from the "address" table. Please do not perform any updates on the "address" table, as this can impact multiple records with the same address.
--Lets chosse customer with at least 43 rentals and 43 payments, to make sure we choose only one I use LIMIt 1.
-- Of course there shouldn't be any customer with my name and surname
--
BEGIN;

savepoint sv_alter_cus;

WITH random_adress_id AS (
	SELECT
		ceil(random() * max(address_id)) AS address_id
	FROM
		address
),
cte_update_customer AS (
	UPDATE
		customer cus
	SET
		first_name = 'Miłosz',
		last_name = 'Czapla',
		address_id = (
			SELECT
				address_id
			FROM
				random_adress_id
		),
		email = 'notyourbusiness@work.com',
		last_update = CURRENT_DATE
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
		)
		AND NOT EXISTS (
			SELECT
				customer_id
			FROM
				customer
			WHERE
				lower(first_name) = 'miłosz'
				AND lower(last_name) = 'czapla'
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

--rollback to savepoint sv_alter_cus;  -- if you want rollback uncomment it 
COMMIT;

--Remove any records related to you (as a customer) from all tables except 'Customer' and 'Inventory'
--Firstly I used dbveaver to fast look for connections and usage of customer, I looked for customer_id as foreign key, it is preasent in rental and payment tables
--We will use customer_id from the previous task, in my case it was 1. 
--we will perform delete on both tables as CTE to make it at once, otherwise there will be an error because some rental have reference in payment and they cannot be deleted without
--deleting referenced rows in other table 
BEGIN;

savepoint sv_remove_data;

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
--SELECT
--	*
--FROM
--	cte_to_delete_me_rental;
--	
SELECT
	*
FROM
	cte_to_delete_me_payment;

--rollback to savepoint sv_remove_data;  -- if you want rollback uncomment it 
COMMIT;

--Rent you favorite movies from the store they are in and pay for them (add corresponding records to the database to represent this activity)
--(Note: to insert the payment_date into the table payment, you can create a new partition (see the scripts to install the training database ) or add records for the
--first half of 2017)
-- I assumed that payment amopunt is connected with amount of days it is rented for + some base amount(0,29 per day and 2,0 as base amount)
--also Store I rent from is with store_id = 1 and staff_id = 1,
--it should be probaly the one that is closer to my address to be honest
BEGIN;

savepoint sv_rent_films;

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
		AND store_id = 1
),
rent_films AS (
	INSERT INTO
		rental (
			rental_date,
			return_date,
			inventory_id,
			customer_id,
			staff_id,
			last_update
		)
	SELECT
		'2017-01-15 10:30:00' :: timestamp,
		'2017-01-15 10:30:00' :: timestamp + (crf.rental_duration * INTERVAL '1 days') AS return_date,
		crf.inventory_id,
		1 AS customer_id,
		1 AS staff_id,
		CURRENT_DATE
	FROM
		cte_rent_fav crf RETURNING *
) --I find that weird payment table does't have last_update column
INSERT INTO
	payment (
		customer_id,
		staff_id,
		rental_id,
		amount,
		payment_date
	)
SELECT
	rf.customer_id,
	rf.staff_id,
	rf.rental_id,
	crf.rental_duration * 0.29 + 2.0 AS amount,
	rf.return_date AS payment_date
FROM
	rent_films rf
	INNER JOIN cte_rent_fav crf ON rf.inventory_id = crf.inventory_id RETURNING *;

--rollback to savepoint sv_rent_films;  -- if you want rollback uncomment it 
COMMIT;

--Note: 
--All new & updated records must have 'last_update' field set to current_date.
--Double-check your DELETEs and UPDATEs with SELECT query before committing the transaction!!! 
--Your scripts must be rerunnable/reusable and don't produces duplicates. You can use WHERE NOT EXISTS, IF NOT EXISTS, ON CONFLICT DO NOTHING, etc.
--Don't hardcode IDs. Instead of construction INSERT INTO … VALUES use INSERT INTO … SELECT …
--Don't forget to add RETURNING
--Please add comments why you chose a particular way to solve each tasks.
--
--