select * from sales;
select * from menu;
select * from members;

-- 1. What is the total amount each customer spent at the restaurant?

select 
	sales.customer_id,
	sum(menu.price) as total_sales from sales
	inner join menu on sales.product_id = menu.product_id
group by sales.customer_id;

-- Customer A spent 76.
-- Customer B spent 74.
-- Customer C spent 36.

--2. How many days has each customer visited the restaurant?

select
	customer_id, 
	count ( distinct order_date) as visit_count
from sales
group by customer_id;

-- Customer A visited 4 times.
-- Customer B visited 6 times.
-- Customer C visited 2 times.

-- 3. What was the first item from the menu purchased by each customer?

with cte as (
select 
	sales.customer_id,
	menu.product_name,
	sales.order_date,
	dense_rank() over (partition by sales.customer_id order by sales.order_date) rnk
from menu
inner join sales on sales.product_id = menu.product_id
)

select
	customer_id,
	product_name
from cte
where rnk = 1
group by customer_id, product_name;

-- Customer A’s first order are curry and sushi.
-- Customer B’s first order is curry.
-- Customer C’s first order is ramen.

-- 4.What is the most purchased item on the menu and how many times was it purchased by all customers?

select top 1
	menu.product_name, count(menu.product_name) as most_purchased
from sales
inner join menu on sales.product_id = menu.product_id
group by  menu.product_name
order by most_purchased desc;

-- 5. Which item was the most popular for each customer ?

with cte as
(
select 
	sales.customer_id, menu.product_name, count(menu.product_name) as order_count,
	dense_rank() over (partition by sales.customer_id order by count(menu.product_name)desc) as rnk
from sales
inner join  menu ON sales.product_id = menu.product_id
group by sales.customer_id, menu.product_name
)

select customer_id, product_name, order_count from cte
where rnk = 1

-- Customer A and C’s favourite item is ramen.
-- Customer B enjoys all items on the menu. He/she is a true foodie.

--6. Which item was purchased first by the customer after they became a member?

with cte as (
select 
	sales.customer_id, menu.product_name, sales. order_date,
	dense_rank() over (partition by sales.customer_id order by sales.order_date) as rnk
	from sales
inner join members on sales.customer_id= members.customer_id
inner join menu on  sales.product_id = menu.product_id
and sales.order_date > members.join_date
)
select customer_id, product_name from cte
where rnk = 1

-- Customer A’s first order as a member is ramen.
-- Customer B’s first order as a member is sushi.

--7	Which item was purchased just before the customer became a member?

with cte as(
select 
	sales.customer_id, menu.product_name, sales.order_date,
	DENSE_RANK() over (partition by sales.customer_id order by sales.order_date) as rnk
from sales
inner join menu on sales.product_id = menu.product_id
inner join members on sales.customer_id = members.customer_id
and sales.order_date < members.join_date
)
select customer_id, product_name from cte
where rnk = 1;

-- 8. What is the total items and amount spent for each member before they became a member?

select 
	sales.customer_id, count(sales.product_id) as total_items, sum(menu.price) as total_price
from sales
inner join members on members.customer_id = sales.customer_id
inner join menu on menu.product_id = sales.product_id
and sales.order_date < members.join_date
group by sales.customer_id

-- Customer A spent 25 on 2 items.
-- Customer B spent 40 on 3 items.

-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

select * from menu;
select * from sales;
select * from members;

with cte as (
select 
	sales.customer_id, menu.product_name, menu.price,
	case 
	when menu.product_name = 'sushi' then price * 20
	else
	price * 10
	end as points
from sales
inner join menu on sales.product_id = menu.product_id
)
select customer_id, sum(points) as total_points
from cte
group by customer_id;

-- The total points for Customers A, B and C are $860, $940 and $360 respectively.

-- 10. In the first week after a customer joins the program (including their join date)
-- they earn 2x points on all items, not just sushi — how many points do customer A and B have at the end of January?

select
	sales.customer_id, menu.price, (menu.price * 2) as total_points
from sales
inner join menu on  menu.product_id = sales.product_id
inner join members on sales.customer_id = members.customer_id
and members.join_date >= sales.order_date

with cte as (
select
	sales.customer_id, members.join_date, sales.order_date, DATEADD(DAY,6, members.join_date) as 'new_date', menu.price, menu.product_name,
	case
		when menu.product_name = 'sushi' then menu.price * 2 * 10
		when sales.order_date between members.join_date and DATEADD(DAY,6, members.join_date) then (menu.price) * 2 * 10
		else
		menu.price * 10
	end as total_points
from sales
inner join menu on menu.product_id = sales.product_id
inner join members on sales.customer_id = members.customer_id
)
select customer_id, sum(total_points)
from cte
where order_date between '2021-01-01' and '2021-01-31'group by customer_id

-- Customer A has 1,370 points.
-- Customer B has 820 points.
