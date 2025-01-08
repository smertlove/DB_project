
-- CRUD - Update (not Insert)
UPDATE
    Customer
SET
    name = "Dilan"
WHERE
    email = "derek.derekov@example.com"
;

-- CRUD - Delete
DELETE FROM
    Coffee_update_log
WHERE
    amount = 0
;


-- "with", "group by", "having"
-- У кого в Дарнассе больше 100 кофе

WITH
    bureaucratic_CustomerCoffeeAmount
AS (
    SELECT
        customer_email,
        city_name,
        SUM(amount) AS c_amount
    FROM
        Coffee_update_log
    GROUP BY
        customer_email, city_name
    HAVING
        c_amount > 0
)

SELECT
    customer_email, city_name, c_amount
FROM
    bureaucratic_CustomerCoffeeAmount
WHERE
    city_name = "Darnassus"
    AND
    c_amount > 100
;


-- "order by", "аггрегация в результате"
-- Богатство клиентов

SELECT
    customer_email, SUM(c_amount) s_amount
FROM
    CustomerCoffeeAmount
GROUP BY
    customer_email
ORDER BY
    s_amount DESC
;



-- "Where с объединением трёх таблиц в where", "order by"
-- Латте в Штормграде

SELECT
    Customer.name ,
    Coffee.name ,
    Coffee.time_to_make ,
    Order_log.sold_at,
    City.name
FROM
    Customer, Order_log, Coffee, City
WHERE
    Customer.email = Order_log.customer_email
    AND Order_log.coffee_name = Coffee.name
    AND Order_log.city_name = City.name
    AND City.name = "Stormwind"
    AND Coffee.name = "Latte"
ORDER BY
    Order_log.sold_at DESC;



-- "Вложенный select какой-нибудь", "хороший", "group by", "аггрегация в where" (kind of), "having"
-- Найти пользователей, которые пополняли счёт, но не пили кофе.

SELECT
    Customer.name, Customer.email
FROM
    Customer
WHERE
    Customer.email IN ( -- <- "хороший"
        SELECT
            Coffee_update_log.customer_email
        FROM
            Coffee_update_log
        GROUP BY
            Coffee_update_log.customer_email
        HAVING
            SUM(amount) > 0
    )
    AND
    Customer.email NOT IN (  -- <- "какой-нибудь"
        SELECT DISTINCT
            Order_log.customer_email
        FROM
            Order_log
    )
;


-- "join", "left/right join"
-- Паддинг для всех комбинаций пользователь-город

INSERT INTO
    Coffee_update_log (customer_email, city_name, amount)
SELECT
    customer.email,
    city.name,
    0
FROM
    Customer customer
    CROSS JOIN  -- <- "join"
    City city
    LEFT JOIN   -- <- "left/right join"
    Coffee_update_log cul ON customer.email = cul.customer_email AND city.name = cul.city_name
WHERE
    cul.customer_email IS NULL
;

