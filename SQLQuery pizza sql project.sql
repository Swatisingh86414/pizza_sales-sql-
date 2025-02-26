
USE PIZZAHUT
 select * from dbo.Pizzas
  select * from dbo.orders
  select * from dbo.order_details
  select * from dbo.pizza_types

  
 --1 Retrieve the total number of orders placed.

 select count(order_id) as total_orders from orders;

 --2 Calculate the total revenue generated from pizza sales.

 select 
 round(sum (order_details.quantity *pizzas.price),2) as total_sales
 from order_details join pizzas on pizzas.pizza_id =order_details.pizza_id 

 --3  Identify the highest-priced pizza.

 SELECT TOP 1 pizza_types.name, pizzas.price
FROM pizza_types
JOIN pizzas ON pizza_types.pizza_type_id = pizzas.pizza_type_id
ORDER BY pizzas.price DESC;

--4 Identify the most common pizza size ordered.

 select pizzas.size, count (order_details.order_details_id) as order_count
 from pizzas 
 join  order_details
 on pizzas.pizza_id=order_details.pizza_id
 group by pizzas.size 
 order by order_count desc;

  --5 List the top 5 most ordered pizza types along with their quantities.

  SELECT TOP 5 pizza_types.name, SUM(TRY_CAST(order_details.quantity AS INT)) AS quantity
FROM pizza_types
JOIN pizzas ON pizza_types.pizza_type_id = pizzas.pizza_type_id
JOIN order_details ON order_details.pizza_id = pizzas.pizza_id
GROUP BY pizza_types.name
ORDER BY quantity DESC;

--6 Join the necessary tables to find the total quantity of each pizza category ordered.

SELECT pizza_types.category, 
       SUM(CAST(order_details.quantity AS INT)) AS quantity
FROM pizza_types
JOIN pizzas 
ON pizza_types.pizza_type_id = pizzas.pizza_type_id
JOIN order_details
ON order_details.pizza_id = pizzas.pizza_id
GROUP BY pizza_types.category
ORDER BY quantity DESC;

--7 Determine the distribution of orders by hour of the day.

SELECT DATEPART(HOUR, time) AS hour, COUNT(order_id) AS order_count
FROM orders
GROUP BY DATEPART(HOUR, time)
ORDER BY hour;

--8 Join relevant tables to find the category-wise distribution of pizzas.

select category ,count (name) from pizza_types
group by category;

--9 Group the orders by date and calculate the average number of pizzas ordered per day.


SELECT AVG(total_quantity) AS average_quantity
FROM (
    SELECT orders.date, SUM(CAST(order_details.quantity AS INT)) AS total_quantity
    FROM orders
    JOIN order_details
    ON orders.order_id = order_details.order_id
    GROUP BY orders.date
) AS order_quantity;

--10 Determine the top 3 most ordered pizza types based on revenue.

SELECT TOP 3 pt.name AS pizza_name,
           SUM(CAST(od.quantity AS INT) * p.price) AS total_revenue
FROM order_details od
JOIN pizzas p ON od.pizza_id = p.pizza_id
JOIN pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.name
ORDER BY total_revenue DESC;

--11 Calculate the percentage contribution of each pizza type to total revenue.

SELECT pt.name AS pizza_name,
       SUM(CAST(od.quantity AS INT) * p.price) AS total_revenue,
       (SUM(CAST(od.quantity AS INT) * p.price) * 100.0 / 
        (SELECT SUM(CAST(quantity AS INT) * price)
         FROM order_details
         JOIN pizzas ON order_details.pizza_id = pizzas.pizza_id)) AS revenue_percentage
FROM order_details od
JOIN pizzas p ON od.pizza_id = p.pizza_id
JOIN pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.name
ORDER BY revenue_percentage DESC;

--12 Analyze the cumulative revenue generated over time.

SELECT orders.date AS order_date,
       SUM(CAST(order_details.quantity AS INT) * pizzas.price) AS daily_revenue,
       SUM(SUM(CAST(order_details.quantity AS INT) * pizzas.price)) 
           OVER (ORDER BY orders.date) AS cumulative_revenue
FROM orders
JOIN order_details ON orders.order_id = order_details.order_id
JOIN pizzas ON order_details.pizza_id = pizzas.pizza_id
GROUP BY orders.date
ORDER BY orders.date;

--13 Determine the top 3 most ordered pizza types based on revenue for each pizza category.

WITH PizzaRevenue AS (
    SELECT pt.category,
           pt.name AS pizza_name,
           SUM(CAST(od.quantity AS INT) * p.price) AS total_revenue,
           ROW_NUMBER() OVER (PARTITION BY pt.category ORDER BY SUM(CAST(od.quantity AS INT) * p.price) DESC) AS rank
    FROM order_details od
    JOIN pizzas p ON od.pizza_id = p.pizza_id
    JOIN pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
    GROUP BY pt.category, pt.name
)
SELECT category, pizza_name, total_revenue
FROM PizzaRevenue
WHERE rank <= 3
ORDER BY category, rank;
