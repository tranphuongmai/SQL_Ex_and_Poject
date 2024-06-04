SHOW databases;
USE toys_and_models;

/*Quantités du moi Février*/;
SELECT  SUM(quantityOrdered*priceEach) as totalSale, orderDate 
FROM ((orderdetails
JOIN products ON products.productCode = orderdetails.productCode)
JOIN orders   ON orders.orderNumber = orderdetails.orderNumber)
WHERE orderDate between '2024-02-01' and '2024-02-20'
group by orderDate
Order by orderDate;

/*Proportion de Produits vendus en 2024*/;
SELECT productLine, SUM(quantityOrdered) as totalQuantity
FROM ((orderdetails
JOIN products ON products.productCode = orderdetails.productCode)
JOIN orders   ON orders.orderNumber = orderdetails.orderNumber)
WHERE orderDate between '2024-01-01' and '2024-02-20'
group by productLine;

/* Quantité totale par Catégories et Mois*/;
SELECT productLine, SUM(quantityOrdered) as totalQuantity,
MONTH(orderDate) as month
FROM ((orderdetails
JOIN products ON products.productCode = orderdetails.productCode)
JOIN orders   ON orders.orderNumber = orderdetails.orderNumber)
WHERE orderDate between '2024-01-01' and '2024-02-20'
group by productLine, month
Order by month;

/*KPI de même période de l'année dernière*/;
SELECT productLine, SUM(quantityOrdered) as totalQuantity, 
YEAR(orderDate) as year
FROM ((orderdetails
JOIN products ON products.productCode = orderdetails.productCode)
JOIN orders   ON orders.orderNumber = orderdetails.orderNumber)
WHERE orderDate between '2024-01-01' and '2024-02-20'
Or orderDate between '2023-01-01' and '2023-02-28'
group by productLine, year
Order by year;


/* ###VENTES QUESTION Le nombre de produits vendus par catégorie et par mois de l'année 2024*/;
SELECT 
   productLine,
   COALESCE(SUM(CASE WHEN orderDate BETWEEN '2024-02-01' AND '2024-02-20' THEN quantityOrdered END), 0) AS totalQuantity_feb,
   COALESCE(SUM(CASE WHEN orderDate BETWEEN '2024-01-01' AND '2024-01-31' THEN quantityOrdered END), 0) AS totalQuantity_jan,
   COALESCE(SUM(CASE WHEN orderDate BETWEEN '2024-02-01' AND '2024-02-20' THEN quantityOrdered END), 0) -  
   COALESCE(SUM(CASE WHEN orderDate BETWEEN '2024-01-01' AND '2024-01-31' THEN quantityOrdered END), 0) AS Evolution
FROM ((orderdetails
	JOIN products ON products.productCode = orderdetails.productCode)
	JOIN orders   ON orders.orderNumber = orderdetails.orderNumber)
GROUP BY productLine;


/*  ###VENTES QUESTION Le nombre de produits vendus par catégorie et par mois de l'année 2023 et 2024*/;
WITH tab_1 AS (
SELECT 
   productLine,
   COALESCE(SUM(CASE WHEN orderDate BETWEEN '2024-01-01' AND '2024-01-31' THEN quantityOrdered END), 0) AS totalQuantity_jan_2024,
   COALESCE(SUM(CASE WHEN orderDate BETWEEN '2023-01-01' AND '2023-01-31' THEN quantityOrdered END), 0) AS totalQuantity_jan_2023,
   COALESCE(SUM(CASE WHEN orderDate BETWEEN '2024-02-01' AND '2024-02-20' THEN quantityOrdered END), 0) AS totalQuantity_feb_2024,
   COALESCE(SUM(CASE WHEN orderDate BETWEEN '2023-02-01' AND '2024-02-28' THEN quantityOrdered END), 0) AS totalQuantity_feb_2023
FROM ((orderdetails
	JOIN products ON products.productCode = orderdetails.productCode)
	JOIN orders   ON orders.orderNumber = orderdetails.orderNumber)
GROUP BY productLine ) 

SELECT productLine, totalQuantity_jan_2024, totalQuantity_jan_2023, 
totalQuantity_jan_2024 - totalQuantity_jan_2023 AS EVOLUTION_JAN_23_24,
totalQuantity_feb_2024, totalQuantity_feb_2023, 
totalQuantity_feb_2024 - totalQuantity_feb_2023 AS EVOLUTION_FEB_23_24
FROM tab_1;

/* ### HR QUESTIONd MEthod 2 using RANK() OVER() and subqueries*/
SELECT employeeNumber, lastName, firstName, jobTitle, totalSales, month, year, staffRank
FROM (
  SELECT employeeNumber, lastName, firstName, jobTitle, SUM(quantityOrdered*priceEach) AS totalSales, MONTH(orderDate) AS month,YEAR(orderDate) AS year,
  RANK() OVER(partition by  MONTH(orderDate) ORDER BY SUM(quantityOrdered*priceEach) DESC) AS staffRank
  FROM (((customers
	JOIN employees 		ON employees.employeeNumber = customers.salesRepEmployeeNumber)
	JOIN orders  		ON orders.customerNumber = customers.customerNumber)
	JOIN orderdetails 	ON orders.orderNumber = orderdetails.orderNumber)
	WHERE orderDate BETWEEN '2024-01-01' AND '2024-02-20'
	GROUP BY employeeNumber, MONTH(orderDate), YEAR(orderDate)
    ) ranked_sales
    WHERE staffRank <= 2;
    
    /* Le stock des 5 produits les plus commandés (Pour gérer le stock)*/;
    
SELECT productName, SUM(quantityOrdered), quantityInStock
 FROM ((products 
 JOIN orderdetails	ON products.productCode = orderdetails.productCode)
 JOIN orders 		ON orders.orderNumber = orderdetails.orderNumber)
 GROUP BY   productName, quantityInStock
 ORDER BY  SUM(quantityOrdered) DESC LIMIT 5;
 
/*### FINANCE QUESTION Le chiffre d'affaires des commandes des deux derniers mois de la base de données par pays.*/; 
/* Pour montrer que les chiffres d'affaire augmentent ou non*/
 WITH tab_3 AS (
SELECT 
   country, 
   COALESCE(SUM(CASE WHEN orderDate BETWEEN '2024-02-01' AND '2024-02-20' THEN quantityOrdered*priceEach END), 0) AS sales_feb_2024,
   COALESCE(SUM(CASE WHEN orderDate BETWEEN '2024-01-01' AND '2024-01-31' THEN quantityOrdered*priceEach END), 0) AS sales_jan_2024,
   COALESCE(SUM(CASE WHEN orderDate BETWEEN '2023-12-01' AND '2024-12-31' THEN quantityOrdered*priceEach END), 0) AS sales_dec_2023,
   COALESCE(SUM(CASE WHEN orderDate BETWEEN '2023-11-01' AND '2024-11-30' THEN quantityOrdered*priceEach END), 0) AS sales_nov_2023,
   COALESCE(SUM(CASE WHEN orderDate BETWEEN '2023-10-01' AND '2024-10-31' THEN quantityOrdered*priceEach END), 0) AS sales_oct_2023,
   COALESCE(SUM(CASE WHEN orderDate BETWEEN '2023-09-01' AND '2024-09-30' THEN quantityOrdered*priceEach END), 0) AS sales_sep_2023
   
FROM ((customers
JOIN orders  		ON orders.customerNumber = customers.customerNumber)
JOIN orderdetails 	ON orders.orderNumber = orderdetails.orderNumber)
GROUP BY country ) 

SELECT country, sales_feb_2024, sales_jan_2024,
(CASE WHEN sales_feb_2024 - sales_jan_2024 < 0 THEN 0 ELSE sales_feb_2024 - sales_jan_2024 END) AS diff_feb_jan,
(CASE WHEN sales_jan_2024 - sales_dec_2023 < 0 THEN 0 ELSE sales_jan_2024 - sales_dec_2023 END) AS diff_jan_dec,
(CASE WHEN sales_dec_2023 - sales_nov_2023 < 0 THEN 0 ELSE sales_dec_2023 - sales_nov_2023 END) AS diff_dec_nov, 
(CASE WHEN sales_nov_2023 - sales_oct_2023 < 0 THEN 0 ELSE sales_nov_2023 - sales_oct_2023 END) AS diff_nov_oct,
(CASE WHEN sales_oct_2023 - sales_sep_2023 < 0 THEN 0 ELSE sales_oct_2023 - sales_sep_2023 END) AS diff_oct_sep
FROM tab_3; 

/*### FINANCE QUESTION Le chiffre d'affaires des commandes des deux derniers mois de la base de données par pays.*/; 
/* Pour montrer vraiment les évolutions des chiffres d'affaire*/
WITH tab_2 AS (
SELECT 
   country, 
   COALESCE(SUM(CASE WHEN orderDate BETWEEN '2024-02-01' AND '2024-02-20' THEN quantityOrdered*priceEach END), 0) AS sales_feb_2024,
   COALESCE(SUM(CASE WHEN orderDate BETWEEN '2024-01-01' AND '2024-01-31' THEN quantityOrdered*priceEach END), 0) AS sales_jan_2024,
   COALESCE(SUM(CASE WHEN orderDate BETWEEN '2023-12-01' AND '2024-12-31' THEN quantityOrdered*priceEach END), 0) AS sales_dec_2023,
   COALESCE(SUM(CASE WHEN orderDate BETWEEN '2023-11-01' AND '2024-11-30' THEN quantityOrdered*priceEach END), 0) AS sales_nov_2023,
   COALESCE(SUM(CASE WHEN orderDate BETWEEN '2023-10-01' AND '2024-10-31' THEN quantityOrdered*priceEach END), 0) AS sales_oct_2023,
   COALESCE(SUM(CASE WHEN orderDate BETWEEN '2023-09-01' AND '2024-09-30' THEN quantityOrdered*priceEach END), 0) AS sales_sep_2023
FROM ((customers
JOIN orders  		ON orders.customerNumber = customers.customerNumber)
JOIN orderdetails 	ON orders.orderNumber = orderdetails.orderNumber)
GROUP BY country ) 

SELECT country, sales_feb_2024, sales_jan_2024,
sales_feb_2024 - sales_jan_2024 AS diff_2_1,
sales_jan_2024 - sales_dec_2023 AS diff_1_12,
sales_dec_2023 - sales_nov_2023 AS diff_12_11,
sales_nov_2023 - sales_oct_2023 AS diff_11_10,
sales_oct_2023 - sales_sep_2023 AS diff_10_9
FROM tab_2; 
