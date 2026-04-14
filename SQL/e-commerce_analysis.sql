/* 
1. Market segmentation analysis: Top 3 cities with the highest noumber of customers 
in order to determine key markets for targeted marketing and logistics optimization.
*/
select location, count(cust_id) as cnt 
from Customers 
group by location 
order by cnt desc 
limit 3;

/* 
2. Engagement depth analysis: Distribution of customers by the number of orders placed.
*/
select NumberOfOrders, count(*) CustomerCount from 
	( select count(order_id) NumberOfOrders, case
	when count(order_id) = 1 then 'One-time buyer.' 
	when count(order_id) between 2 and 4 then 'Occassional Shoppers.'
	else 'Regular customers.' end as Terms	
	from Orders group by customer_id ) as tab
group by NumberOfOrders order by NumberOfOrders;

/* 
3. Purchase high-value products: Identify products where average purchase quantity per order is 2 
but with high total revenue
*/
select product_id, avg(quantity) AvgQuantity, sum(quantity*price_per_unit) TotalRevenue
from OrderDetails 
group by product_id 
having avg(quantity) = 2 
order by TotalRevenue desc;

/*
4. Category-wise Customer Reach: For each product category, calculate unique number of customers purchasing from it.
*/
select p.category, count(distinct o.customer_id) unique_customers 
from Products p join OrderDetails od on 
od.product_id = p.product_id
join Orders o on 
od.order_id = o.order_id 
group by p.category 
order by unique_customers desc;

/*
5. Sales Trend Analysis: month-on-month percentage change in total sales
*/
with cte as (
	select date_format(order_date, '%Y-%m') as month, 
	sum(total_amount) as total_sales 
	from Orders 
	group by date_format(order_date, '%Y-%m')
    )
select month, total_sales, 
round((total_sales - lag(total_sales)  over(order by month))*100.0/lag(total_sales) over(order by month),2) as percent_change 
from cte;

/*
6. Average Order Value Fluctuation: month-on-month average order value change
*/
with cte as (
	select date_format(order_date, '%Y-%m') as month, round(avg(total_amount),2) as avg_amt 
	from Orders group by date_format(order_date, '%Y-%m')
    )
select month, avg_amt, round(avg_amt - lag(avg_amt) over(order by month),2) as changeInValue 
from cte order by changeInValue desc;

/*
7. Inventory Refresh Rate: Based on sales data, identify products with the fastest turnover rates, 
suggesting high demand and the need for frequent restocking.
*/
select prod_id, count(order_id) sales_freq 
from OrderDetails 
group by prod_id 
order by sales_freq 
desc limit 5; 

/*
8. Low Engagement Products: List products purchased by less than 40% of the customer base, 
indicating potential mismatches between inventory and customer interest.
*/
select p.product_id prod_id, p.product_name prod_name, count(distinct o.customer_id) unique_cus_cnt
from Products p join OrderDetails od 
on p.product_id = od.product_id
join Orders o 
on od.order_id = o.order_id 
group by p.product_id, p.product_name
having count(distinct o.customer_id) < (select 0.4*count(customer_id) from Customers);

/*
9. Customer Acquisition Trends: Evaluate the month-on-month growth rate in the customer base to understand 
the effectiveness of marketing campaigns and market expansion efforts.
*/
select date_format(order_date, '%Y-%m') as firstPurchaseMon, 
count(customer_id) totalNewCus from (
	select customer_id, min(order_date) as order_date 
	from Orders 
    group by customer_id) sub
group by date_format(order_date, '%Y-%m')
order by firstPurchaseMon;