--Task 1. Create a view
--Create a view called 'sales_revenue_by_category_qtr' that shows the film category and total sales revenue for the current quarter and year. The view should only display categories with at least one sale in the current quarter. 
--Note: when the next quarter begins, it will be considered as the current quarter.
DO $$
BEGIN
    -- Check if the view already exists
    IF EXISTS (SELECT 1 FROM information_schema.views WHERE table_name = 'sales_revenue_by_category_qtr') THEN
        RAISE NOTICE 'View sales_revenue_by_category_qtr already exists. Skipping creation.';
    ELSE
        CREATE VIEW sales_revenue_by_category_qtr AS
        SELECT
            c.name AS category_name,
            SUM(p.amount) AS total_revenue
        FROM
            category c
		JOIN film_category fc ON fc.category_id = c.category_id  
        JOIN film f ON fc.film_id = f.film_id
        JOIN inventory i ON f.film_id = i.film_id
        JOIN rental r ON i.inventory_id = r.inventory_id
        JOIN payment p ON r.rental_id = p.rental_id
        WHERE
            DATE_PART('quarter', r.rental_date) = DATE_PART('quarter', CURRENT_DATE)
            AND DATE_PART('year', r.rental_date) = DATE_PART('year', CURRENT_DATE)
        GROUP BY c.name
        HAVING SUM(p.amount) > 0; -- Only categories with sales in the current quarter
        RAISE NOTICE 'View sales_revenue_by_category_qtr created successfully.';
    END IF;
END;
$$ LANGUAGE plpgsql;

--test the view
SELECT * FROM sales_revenue_by_category_qtr;

--Task 2. Create a query language functions
--Create a query language function called 'get_sales_revenue_by_category_qtr' that accepts one parameter representing the current quarter and year and returns the same result as the 'sales_revenue_by_category_qtr' view.
DROP FUNCTION IF EXISTS get_sales_revenue_by_category_qtr(INT, INT);

-- Create the query language function
CREATE FUNCTION get_sales_revenue_by_category_qtr(
    quarter INT DEFAULT DATE_PART('quarter', CURRENT_DATE)::INT,
    year INT DEFAULT DATE_PART('year', CURRENT_DATE)::INT
) 
RETURNS TABLE(category_name TEXT, total_revenue NUMERIC) AS $$
    SELECT
        c.name AS category_name,
        SUM(p.amount) AS total_revenue
    FROM
        category c
    JOIN film_category fc ON fc.category_id = c.category_id  
        JOIN film f ON fc.film_id = f.film_id
    JOIN inventory i ON f.film_id = i.film_id
    JOIN rental r ON i.inventory_id = r.inventory_id
    JOIN payment p ON r.rental_id = p.rental_id
    WHERE
        DATE_PART('quarter', r.rental_date) = quarter
        AND DATE_PART('year', r.rental_date) = year
    GROUP BY c.name
    HAVING SUM(p.amount) > 0;
$$ LANGUAGE sql;

--Test the Function with Default Parameters:
SELECT * FROM get_sales_revenue_by_category_qtr();

--Test the Function with Specific Parameters:
SELECT * FROM get_sales_revenue_by_category_qtr(2, 2005);


--Task 3. Create procedure language functions
--Create a function that takes a country as an input parameter and returns the most popular film in that specific country. 
--The function should format the result set as follows:
--                    Query (example):select * from core.most_popular_films_by_countries(array['Afghanistan','Brazil','United States’]);

--I used window function because I couldn't find diffrent solution and this is what internet suggested me
DROP FUNCTION IF EXISTS most_popular_films_by_countries(TEXT[]);

CREATE FUNCTION most_popular_films_by_countries(countries TEXT[])
RETURNS TABLE(
    country TEXT,
    film TEXT,
    rating TEXT,
    language Char(20),
    length INT,
    "Release year" INT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        ranked_films.country,
       ranked_films.film,
      ranked_films.rating,  -- Cast rating to TEXT
     ranked_films.language,
     ranked_films.length::INT,
     ranked_films."Release year"::INT
    FROM (
        SELECT
            co.country AS country,
            f.title AS film,
            f.rating::TEXT AS rating,  -- Cast rating to TEXT
            l.name AS language,
            f.length AS length,
            f.release_year AS "Release year",
            COUNT(r.rental_id) AS rental_count,
            ROW_NUMBER() OVER (PARTITION BY co.country ORDER BY COUNT(r.rental_id) DESC) AS rank -- Rank films by rental count per country
        FROM
            country co
        JOIN city ci ON co.country_id = ci.country_id
        JOIN address a ON ci.city_id = a.city_id
        JOIN customer cu ON a.address_id = cu.address_id
        JOIN rental r ON cu.customer_id = r.customer_id
        JOIN inventory i ON r.inventory_id = i.inventory_id
        JOIN film f ON i.film_id = f.film_id
        JOIN language l ON f.language_id = l.language_id
        WHERE
            co.country = ANY(countries) -- Filter by input countries
        GROUP BY co.country, f.title, f.rating, l.name, f.length, f.release_year
    ) AS ranked_films
    WHERE rank = 1 -- Only return the most popular film for each country
    ORDER BY country; -- Order by country
END;
$$ LANGUAGE plpgsql;

-- Test the Function
SELECT * FROM most_popular_films_by_countries(ARRAY['Afghanistan', 'Brazil', 'United States']);



--Task 4. Create procedure language functions
--Create a function that generates a list of movies available in stock based on a partial title match (e.g., movies containing the word 'love' in their title). 
--The titles of these movies are formatted as '%...%', and if a movie with the specified title is not in stock, return a message indicating that it was not found.
--The function should produce the result set in the following format (note: the 'row_num' field is an automatically generated counter field, starting from 1 and incrementing for each entry, e.g., 1, 2, ..., 100, 101, ...).
--
--                    Query (example):select * from core.films_in_stock_by_title('%love%’);

--I looked at the egzample result of the task, and I think it is about currenlty rented movies, otherwise I dont't see an need to put customer name there
-- it is my assumption for the task
DROP FUNCTION IF EXISTS films_in_stock_by_title(TEXT);

CREATE FUNCTION films_in_stock_by_title(partial_title TEXT)
RETURNS TABLE(
    row_num INT,
    film_title TEXT,
    language TEXT,
    customer_name TEXT,
    rental_date TIMESTAMP
) AS $$
DECLARE
    current_row_num INT := 1; -- Start row numbering from 100
BEGIN
    -- Iterate over the results and assign row numbers manually
    FOR film_title, language, customer_name, rental_date IN
        SELECT
            f.title AS film_title,
            l.name AS language,
            cu.first_name || ' ' || cu.last_name AS customer_name,
            r.rental_date
        FROM film f
        JOIN inventory i ON f.film_id = i.film_id
        JOIN rental r ON i.inventory_id = r.inventory_id
        JOIN customer cu ON r.customer_id = cu.customer_id
        JOIN language l ON f.language_id = l.language_id
        WHERE f.title ILIKE partial_title -- Partial match with case-insensitive
        AND r.return_date IS NULL  -- Only films that are currently rented (not returned)
        ORDER BY f.title  -- Sorting by film title
    LOOP
        -- For each row, return it with the current row number
 		row_num := current_row_num;
        RETURN NEXT;
        current_row_num := current_row_num + 1; -- Increment the row number for next entry
    END LOOP;

    -- If no rows are found, raise an exception
    IF NOT FOUND THEN
        RAISE EXCEPTION 'No films found with the specified title: %', partial_title;
    END IF;

    RETURN;
END;
$$ LANGUAGE plpgsql;

-- Test the function
SELECT * FROM films_in_stock_by_title('%vol%');

-- Test the function
SELECT * FROM films_in_stock_by_title('%love%');


--
--Task 5. Create procedure language functions
--Create a procedure language function called 'new_movie' that takes a movie title as a parameter and inserts a new movie with the given title in the film table. 
--The function should generate a new unique film ID, set the rental rate to 4.99, the rental duration to three days, the replacement cost to 19.99.
--The release year and language are optional and by default should be current year and Klingon respectively. The function should also verify that the language exists in the 'language' table. 
--Then, ensure that no such function has been created before; if so, replace it.
-- Drop the function if it already exists
DROP FUNCTION IF EXISTS new_movie(TEXT, TEXT, INT);

-- Create the new_movie function
CREATE FUNCTION new_movie(
    p_title TEXT,                -- Movie title
    p_language TEXT DEFAULT 'Klingon',  -- Default language is Klingon
    p_release_year INT DEFAULT EXTRACT(YEAR FROM CURRENT_DATE)  -- Default release year is current year
)
RETURNS VOID AS $$
DECLARE
    v_language_id INT;
    v_film_id INT;
BEGIN
    -- Verify that the language exists in the language table
    SELECT language_id INTO v_language_id
    FROM language
    WHERE name = p_language;
    
    -- If no language is found, raise an exception
    IF v_language_id IS NULL THEN
        RAISE EXCEPTION 'Language "%" not found in the language table.', p_language;
    END IF;

    -- Insert new film to film table
    INSERT INTO film (
        title, rental_rate, rental_duration, replacement_cost, release_year, language_id
    )
    VALUES (
        p_title, 
        4.99,                 -- rental_rate
        3,                    -- rental_duration (3 days)
        19.99,                -- replacement_cost
        p_release_year,       -- release_year (current year by default)
        v_language_id         -- language_id
    );

    -- Returning a message or verifying successful insertion
    RAISE NOTICE 'New movie "%" with language "%" added to the film table.', p_title, p_language;

END;
$$ LANGUAGE plpgsql;

-- Test the function
-- Example: Insert a new movie with custom title, language, and release year
SELECT new_movie('New Star Wars', 'English', 2023);

-- Example with the default language 'Klingon' and default current year
SELECT new_movie('Klingon Adventure');

--Task 6. Prepare answers to the following questions
--What operations do the following functions perform: film_in_stock, film_not_in_stock, inventory_in_stock, get_customer_balance, inventory_held_by_customer, rewards_report, last_day? You can find these functions in dvd_rental database.
--Why does ‘rewards_report’ function return 0 rows? Correct and recreate the function, so that it's able to return rows properly.
--Is there any function that can potentially be removed from the dvd_rental codebase? If so, which one and why?
--* The ‘get_customer_balance’ function describes the business requirements for calculating the client balance. Unfortunately, not all of them are implemented in this function. Try to change function using the requirements from the comments.
--* How do ‘group_concat’ and ‘_group_concat’ functions work? (database creation script might help) Where are they used?
--* What does ‘last_updated’ function do? Where is it used?
--* What is tmpSQL variable for in ‘rewards_report’ function? Can this function be recreated without EXECUTE statement and dynamic SQL? Why?


