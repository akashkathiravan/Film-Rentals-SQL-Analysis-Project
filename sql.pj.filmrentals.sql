/************************************************/
 /*  Data analysis using sql on Film - Rental  */
/************************************************/


SELECT * FROM customer WHERE email IS NULL;
SELECT * FROM rental WHERE return_date IS NULL; -- null but it was necessary

SELECT rental_date,return_date 
 FROM rental ;                                  -- check for proper timestamp

create table film_category2 
  like  film_category;
insert into film_category2
  select * from film_category;
  
  select * from film_category2;                  -- creating dummy variable 


-- 0 What is the total revenue per month?

  select * from payment;
select sum(amount) as tol_amount ,
         date_format(payment_date, '%y-%m') as mon_of_year
    from payment 
     group by mon_of_year
          order by mon_of_year;

-- 1 Which store generates the highest total revenue?
select  s.store_id,  sum(amount) as tol_rev
 from payment p
     join rental r on p.rental_id = r.rental_id
     join staff str on r.staff_id = str.staff_id
	join store s on str.store_id = s.store_id
      group by s.store_id
        order by tol_rev desc;

-- 2 What is the average rental revenue per customer?
select * from payment;

select customer_id ,round(avg(amount),2) as avg_amount
    from  payment 
      group by customer_id
          order by avg_amount;
 
 
 -- 3. Which film categories generate the most rentals?
 select  * from rental;
 
 select c.name as category_name , 
			count(r.rental_id) AS count_rentals
    from category c
       join film_category fl_cat on c.category_id = fl_cat.category_id
	   join film flm on  fl_cat.film_id = flm.film_id
       join inventory i on i.film_id = flm.film_id
       join rental r on r.inventory_id= i.inventory_id
          group by category_name
             order by count_rentals desc;
 
-- 4. Which actors appear in the most rented films?
select * from rental;

select a.actor_id, 
   concat(first_name, ' ', last_name) as actor_name , 
   count(r.rental_id) as rental_tol
     from actor a
	join film_actor flm on flm.actor_id = a.actor_id
    join film f on flm.film_id = f.film_id
    join inventory i on i.film_id = f.film_id
    join rental r on r.inventory_id= i.inventory_id
       group by a.actor_id
          order by rental_tol desc ;

-- 5. Which cities generate the highest revenue?    
select * from customer;
    
SELECT ci.city, SUM(p.amount) AS total_revenue
       FROM payment p
    JOIN rental r ON p.rental_id = r.rental_id
    JOIN customer c ON r.customer_id = c.customer_id
	JOIN address a ON c.address_id = a.address_id
	JOIN city ci ON a.city_id = ci.city_id
       GROUP BY ci.city
          ORDER BY total_revenue DESC;
    
  -- 6. Who are the top 10 customers by lifetime spending? 
  
select c.customer_id , 
       concat(first_name ,' ' ,last_name) as namess,
	   sum(p.amount) as tol_spending 
from customer c 
     join payment p on c.customer_id = p.customer_id
        group by c.customer_id 
		order by tol_spending desc 
limit 10;
    
    
-- 7. Which customers rent most frequently?

select c.customer_id ,  concat(first_name ,' ' ,last_name) as namess, count(r.rental_id) as count_they_rented
    from customer c 
join rental r on c.customer_id = r.customer_id 
   group by  c.customer_id
     order by count_they_rented desc;

-- 8. Which customers have not rented anything in the last 30 days?

select c.customer_id , 
     concat(first_name ,' ' ,last_name) as namess , 
     max(r.return_date) as latest_dates
from customer c
    join rental r on c.customer_id=r.customer_id
       group by c.customer_id
	   having latest_dates < date_sub(curdate(), interval 30 day);
   
-- 9. What is the average rental duration for each customer?
select * from rental;

select c.customer_id ,
    concat( c.first_name,' ',c.last_name) as customer_name ,
	avg (datediff(return_date,rental_date)) as avg_due 
    from customer c
join rental r on c.customer_id=r.customer_id
  group by c.customer_id
order by avg_due desc;

-- 10. Which customer segment generates most revenue (low/medium/high spending)?   
select * from payment;

select customer_id, 
	 tol_spend ,
    case 
       when tol_spend < 80 then 'low'  
       when tol_spend between 80 and 100 then 'medium'
       else 'high'
       end as seg_revenue
	from (
    select customer_id, 
	sum(amount) as tol_spend from payment
    group by customer_id
    order by tol_spend) as tol;   
    
-- 11. Which films are rented the most?
  
select  f.film_id, count(r.rental_id) as tol_count 
    from film f
      join inventory i on i.film_id=f.film_id
      join rental r on r.inventory_id=i.inventory_id
          group by f.film_id
		   order by tol_count desc ;
    
-- 12. Which films are rented the least?
 
 select  f.title, count(r.rental_id) as tol_count 
	from film f
      join inventory i on i.film_id=f.film_id
      join rental r on r.inventory_id=i.inventory_id
          group by f.title
          order by tol_count 
limit 40;
 
 -- 13. Which films generate the highest revenue?
 SELECT f.title,
		SUM(p.amount) AS total_revenue
  FROM film f
	JOIN inventory i ON f.film_id = i.film_id
	JOIN rental r ON i.inventory_id = r.inventory_id
    JOIN payment p ON p.rental_id = r.rental_id
       GROUP BY f.film_id
         ORDER BY total_revenue DESC;

-- 14. What is the profitability score of each film (rental_count × rental_rate)?   
select * from payment;
  
SELECT f.title,
	   count(r.rental_id) * f.rental_rate   AS profitability_score
FROM film f
	JOIN inventory i ON f.film_id = i.film_id
	JOIN rental r ON i.inventory_id = r.inventory_id
	JOIN payment p ON p.rental_id = r.rental_id
       group by f.film_id
       ORDER BY profitability_score DESC;
   
-- 15. Which films have declining rentals over time   

with monthly as (
   select f.film_id ,
    count(*) as rentals ,
    date_format( r.rental_date , '%Y-%m' ) as month 
 from film f
 join inventory i on f.film_id=i.film_id
 join rental r on i.inventory_id=r.inventory_id
 group by  f.film_id , month 
 ),
 trent as ( 
    select  film_id , month ,
    rentals , lag(rentals) over (partition by  film_id order by month) as prev_month
    from monthly 
    ) 
    
    select * from trent
      where rentals < prev_month;
 
 
-- 16. How many copies of each film exist in inventory?
  
select * from inventory ;

SELECT f.title , count(i.inventory_id) as copies
FROM film f
   LEFT JOIN inventory i ON f.film_id=i.film_id
    group by f.film_id
     order by copies desc;

-- 17. Which films were never rented?

select f.title , count(r.rental_id) as rentalss
   from film f 
       left join inventory i on f.film_id=i.film_id
	   left join rental r on r.inventory_id=i.inventory_id
  where r.rental_id is null
    group by f.title;


-- 18. What is the average rental rate vs replacement cost by category?
select * from category;

select  c.name as category ,
		 avg(f.rental_rate) as avg_rental_rate ,
		 avg(f.replacement_cost) as avg_rental_cost
	from film f 
	join film_category fc on fc.film_id = f.film_id
    join category c on fc.category_id = c.category_id
           group by c.category_id;

-- 19. How often is inventory utilized (rentals per copy)? (How often each film is rented per copy)
select * from rental ;

select f.title , 
     count(r.rental_id) /count(r.inventory_id) as utilized
 from film f 
	join inventory i on f.film_id=i.film_id
    left join rental r on r.inventory_id=i.inventory_id
        group by f.film_id;

-- 20. Which store is more efficient (rentals per staff member)? 

SELECT st.store_id,
       COUNT(r.rental_id)/COUNT(DISTINCT st.staff_id) AS rentals_per_staff
FROM staff st
    JOIN rental r ON st.staff_id = r.staff_id
     GROUP BY st.store_id;
    
    -- 21.	Which customers have rented the same film more than once? 
    
    
select c.customer_id , f.film_id ,
        concat(first_name ,'', last_name) as names , 
          count(r.rental_id) as times_rented 
from customer c 
	join rental r on c.customer_id=r.customer_id
    join inventory i on r.inventory_id=i.inventory_id
    join film f on i.film_id=f.film_id
         group by  c.customer_id , f.film_id
         having count(r.rental_id) > 1
		 order by times_rented desc ;

-- ------------------------------------------------------------------- change over time 

select DATE_FORMAT(payment_date, '%Y-%m') as payment_by_month,
     sum(amount) as tol_amount ,
		count(distinct (customer_id) )as tol_customer
 from payment
 group by  DATE_FORMAT(payment_date, '%Y-%m')
  order by DATE_FORMAT (payment_date, '%Y-%m') asc;
  
  
select payment_by_month ,
       tol_amount , 
 sum(tol_amount) over ( order by tol_amount) as running_total , tol_customer
       from (
select DATE_FORMAT(payment_date, '%Y-%m') as payment_by_month,
     sum(amount) as tol_amount ,
		count(distinct (customer_id) )as tol_customer
 from payment
 group by  DATE_FORMAT(payment_date, '%Y-%m')
  order by DATE_FORMAT (payment_date, '%Y-%m') asc
  ) t                                                    -- running total 
  
  
  