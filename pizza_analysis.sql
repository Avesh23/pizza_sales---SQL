create table orders(
order_id int not null,
order_date date not null,
order_time time not null,
primary key(order_id)
);

-- if you want to load file directy the file should be present in the folder
-- i.e C:\ProgramData\MySQL\MySQL Server 8.0\Data\pizzahut(database name)

load data infile 'orders.csv' into table orders
fields terminated by ','
ignore 1 lines;

create table order_details(
order_details_id int not null,
order_id int not null,
pizza_id text not null,
quantity int not null,
primary key(order_details_id)
);

-- loading the file which is present in the sql  server
load data infile'order_details.csv' into table order_details
fields terminated by ','
ignore 1 lines;

-- or (loading the file which is present in different folder)
load data infile'D:\Data_Analytics\SQL\pizza_sales\order_details.csv' into table order_details
fields terminated by ','
ignore 1 lines;


select count(*) from order_details;
select count(*) from orders;
select count(*) from pizza_types;
select count(*) from pizzas;

-- Question set 1

-- Q1 Retrieve the total number of orders placed.

select count(order_id) as total_orders from orders;

-- Q2 Calculate the total revenue generated from pizza sales

select round(sum(order_details.quantity*pizzas.price),2) as total_sales
from order_details 
join pizzas on pizzas.pizza_id = order_details.pizza_id;

-- Q3 Identify the highest-priced pizza.

select pizza_types.name,max(pizzas.price)
from pizza_types
join pizzas on pizzas.pizza_type_id = pizza_types.pizza_type_id
order by pizzas.price desc
limit 1;

-- method 2 
select max(price) from pizzas; 


-- Q4 Identify the most common pizza size ordered.

select pizzas.size,sum(order_details.quantity) as order_count
from pizzas 
join order_details on order_details.pizza_id = pizzas.pizza_id 
group by pizzas.size
order by order_count desc;

-- Q5 List the top 5 most ordered pizza types along with their quantities

select pizza_types.name ,
sum(order_details.quantity) as quantity
from pizza_types
join pizzas on pizzas.pizza_type_id = pizza_types.pizza_type_id
join order_details on order_details.pizza_id = pizzas.pizza_id
group by pizza_types.name
order by quantity desc
limit 5;

-- *****************************************************************
-- Question set 2
-- Q1 Join the necessary tables to find the total quantity of each pizza category ordered

select pizza_types.category,sum(order_details.quantity) as quantity
from pizza_types
join pizzas on  pizzas.pizza_type_id = pizza_types.pizza_type_id
join  order_details on order_details.pizza_id = pizzas.pizza_id
group by category 
order by quantity desc;

-- Q2 Determine the distribution of orders by hour of the day

select hour(order_time), count(order_id)
from orders
group by hour(order_time);

-- Q3 Join relevant tables to find the category-wise distribution of pizzas

select category, count(name) from pizza_types
group by category ;

-- Q4 Group the orders by date and calculate the average number of pizzas ordered per day
select round(avg(quantity),0) as avg_pizza_ordered_per_day from
(select orders.order_date, sum(order_details.quantity) as quantity
from orders
join  order_details on order_details.order_id = orders.order_id
group by orders.order_date) as order_quantity;

-- Q5 Determine the top 3 most ordered pizza types based on revenue.
select pizza_types.name, sum(order_details.quantity*pizzas.price) as revenue
from  pizza_types
join pizzas on pizzas.pizza_type_id = pizza_types.pizza_type_id
join order_details on order_details.pizza_id = pizzas.pizza_id
group by pizza_types.name
order by revenue desc
limit 3;

-- Question set 3

-- Q1 Calculate the percentage contribution of each pizza type to total revenue

SELECT 
    pizza_types.category,
    ROUND(SUM(order_details.quantity * pizzas.price) / (SELECT 
                    ROUND(SUM(order_details.quantity * pizzas.price),
                                2) AS total_sales
                FROM
                    order_details
                        JOIN
                    pizzas ON pizzas.pizza_id = order_details.pizza_id) * 100,
            2) AS revenue
FROM
    pizza_types
        JOIN
    pizzas ON pizzas.pizza_type_id = pizza_types.pizza_type_id
        JOIN
    order_details ON order_details.pizza_id = pizzas.pizza_id
GROUP BY pizza_types.category
ORDER BY revenue DESC;

-- Q2 Analyze the cumulative revenue generated over time.

select order_date,
sum(revenue)  over (order by order_date) as cum_revenue
from 
(select orders.order_date, SUM(order_details.quantity * pizzas.price) as revenue
from order_details
join pizzas on pizzas.pizza_id = order_details.pizza_id
join orders on orders.order_id = order_details.order_id
group by orders.order_date) as sales;

-- Q3 Determine the top 3 most ordered pizza types based on revenue for each pizza category.


select name,revenue
from
(select category,name,revenue,
rank() over(partition by category order by revenue desc) as rn
from 
(select pizza_types.category, pizza_types.name,
round(SUM(order_details.quantity * pizzas.price),2) as revenue
from pizza_types
join pizzas  on pizza_types.pizza_type_id = pizzas.pizza_type_id
join order_details on order_details.pizza_id = pizzas.pizza_id
group by pizza_types.category, pizza_types.name) as a) as b
where rn <=3;
