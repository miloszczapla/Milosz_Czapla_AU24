--1. All animation movies released between 2017 and 2019 with rate more than 1, alphabetical
--Part 1: Write SQL queries to retrieve the following data
--
--All animation movies released between 2017 and 2019 with rate more than 1, alphabetical
select
	*
from
	film f
where
	f.release_year between 2017 and 2019
	--filter data
	and rental_rate > 1
	--filter data
order by
	f.title asc 

----The revenue earned by each rental store since March 2017 (columns: address and address2 – as one column, revenue)
select
	sum(p.amount) as revenue,
	concat(a.address,
	a.address2) as address
from
	store s
inner join inventory i on
	i.store_id = s.store_id
inner join rental r on
	r.inventory_id = i.inventory_id
inner join payment p on
	p.rental_id = r.rental_id
inner join address a on
	a.address_id = s.address_id
	--get stores addresses
where
	p.payment_date > '01.03.2017'
	--filter
group by
	s.store_id,
	address ,
	address2
	----Top-5 actors by number of movies (released since 2015) they took part in (columns: first_name, last_name, number_of_movies, sorted by number_of_movies in descending order)
select
	first_name,
	last_name,
	count(f2.film_id) as number_of_movies
from
	actor a2
inner join film_actor fa on
	fa.actor_id = a2.actor_id
inner join film f2 on
	f2.film_id = fa.film_id
group by
	a2.actor_id
order by
	number_of_movies desc
limit 5
--Number of Drama, Travel, Documentary per year (columns: release_year, number_of_drama_movies, number_of_travel_movies, number_of_documentary_movies), sorted by release year in descending order. Dealing with NULL values is encouraged)
select
	release_year,
	count(case when c.name = 'Drama' then 1 end) as number_of_drama_movies,
	count(case when c.name = 'Travel' then 1 end) as number_of_travel_movies,
	count(case when c.name = 'Documentary' then 1 end) as number_of_documentary_movies
from
	film f
inner join film_category fc on
	fc.film_id = f.film_id
inner join category c on
	c.category_id = fc.category_id
group by
	f.release_year
order by
	f.release_year desc
for each client,
	display a list of horrors that he had ever rented (in one column,
	separated by commas),
	and the amount of money that he paid for it
select
	c.customer_id,
	c.first_name,
	c.last_name,
	STRING_AGG(f.title,
	',' ) as horror_movies,
	SUM(p.amount) as total_paid
from
	customer c
left join rental r on
	c.customer_id = r.customer_id
left join inventory i on
	i.inventory_id = r.inventory_id
left join payment p on
	r.rental_id = p.rental_id
inner join film f on
	f.film_id = i.film_id
inner join film_category fc on
	fc.film_id = f.film_id
left join category c2 on
	fc.category_id = c2.category_id
where
	c2.name = 'Horror'
group by
	c.customer_id


--
--Part 2: Solve the following problems using SQL
--
--1. Which three employees generated the most revenue in 2017? They should be awarded a bonus for their outstanding performance. 
--Assumptions: 
--staff could work in several stores in a year, please indicate which store the staff worked in (the last one);
--if staff processed the payment then he works in the same store; 
--take into account only payment_date

select
	s.staff_id,
	s.first_name,
	s.last_name,
	sum(p.amount) as revenue ,
	max(s2.store_id) as last_store
from
	staff s
right join store s2 on
	s2.store_id = s.store_id
inner join inventory i on
	i.store_id = s2.store_id
	--revenue depends on person renting staff
inner join rental r on
	r.staff_id = s.staff_id
inner join payment p on
	p.rental_id = r.rental_id
where
	extract(year
from
	r.rental_date) = 2017
group by
	s.staff_id,
	s2.store_id
order by
	revenue desc
limit 3 

--2. Which 5 movies were rented more than others (number of rentals), and what's the expected age of the audience for these movies? To determine expected age please use 'Motion Picture Association film rating system
select
	distinct f.rating
from
	film f 

select
	f.title,
	COUNT(r.rental_id) as rental_count,
	case
		--case to translate film rating to age
    when f.rating = 'G' then 'All ages'
		when f.rating = 'PG' then '10+'
		when f.rating = 'PG-13' then '13+'
		when f.rating = 'R' then '17+'
		when f.rating = 'NC-17' then '18+'
		else 'Unknown'
	end as expected_age
from
	film f
inner join inventory i on
	f.film_id = i.film_id
inner join rental r on
	i.inventory_id = r.inventory_id
group by
	f.title,
	f.rating
order by
	rental_count desc
limit 5

--Part 3. Which actors/actresses didn't act for a longer period of time than the others? 
--The task can be interpreted in various ways, and here are a few options:
--V1: gap between the latest release_year and current year per each actor;

select
	a.actor_id ,
	a.first_name ,
	a.last_name ,
	extract(year
from
	current_date) - max(f.release_year) as year_gap
	--finiding biggest year gap per actor
from
	actor a
inner join film_actor fa on
	fa.actor_id = a.actor_id
inner join film f on
	f.film_id = fa.film_id
group by
	a.actor_id,
	f.release_year
order by
	year_gap desc
	--sorting descending, from biggest year gap

--V2: gaps between sequential films per each actor;
--
--It would be plus if you could provide a solution for each interpretation
--
--
--Note:
--Please add comments why you chose a particular way to solve each tasks.
--IDs should not be hardcoded
--Don't use column number in GROUP BY and ORDER BY
--Specify JOIN types (INNER/RIGHT/LEFT/CROSS)
--Use code formatting standards
--You cannot use window functions
--We request you test your work before commit it. Code should run w/o errors
--


