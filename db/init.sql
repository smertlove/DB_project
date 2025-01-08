/*
********************************************************************************
*                                                                              *
*   4. Кафедральные кофе-машины поставили во всех столицах Альянса.            *
*      Теперь пользователи хранят и тратят кофе из 3 мест (счета раздельные).  *
*      Пользователи делают заказы по паролю.                                   *
*                                                                              *
********************************************************************************
*/



DROP DATABASE IF EXISTS `CoffeeDB`;
CREATE DATABASE `CoffeeDB`        ;
USE `CoffeeDB`                    ;


SET NAMES UTF8                            ;
SET CHARACTER SET UTF8                    ;
SET collation_connection='utf8_general_ci';
SET collation_database='utf8_general_ci'  ;
SET collation_server='utf8_general_ci'    ;
SET character_set_client='utf8'           ;
SET character_set_connection='utf8'       ;
SET character_set_database='utf8'         ;
SET character_set_results='utf8'          ;
SET character_set_server='utf8'           ;


CREATE TABLE IF NOT EXISTS Customer (
    email                      VARCHAR(255)  PRIMARY KEY                 NOT NULL ,
    name                       VARCHAR(255)                              NOT NULL ,
    date_time_of_registration  DATETIME      DEFAULT CURRENT_TIMESTAMP   NOT NULL ,
    password_hash              CHAR(255)                                 NOT NULL
);

CREATE TABLE IF NOT EXISTS City (
    name                       VARCHAR(255)  PRIMARY KEY                 NOT NULL
);

CREATE TABLE IF NOT EXISTS Coffee_update_log (
    id                         INT           PRIMARY KEY AUTO_INCREMENT  NOT NULL ,
    updated_at                 DATETIME      DEFAULT CURRENT_TIMESTAMP   NOT NULL ,
    amount                     BIGINT                                    NOT NULL ,
    customer_email             VARCHAR(255)                              NOT NULL ,
    city_name                  VARCHAR(255)                              NOT NULL ,

    FOREIGN KEY (customer_email) REFERENCES Customer (email),
    FOREIGN KEY (city_name     ) REFERENCES City     (name )
);

CREATE TABLE IF NOT EXISTS Coffee (
    name                       VARCHAR(255)  PRIMARY KEY                 NOT NULL ,
    amount_needed              BIGINT                                    NOT NULL ,
    time_to_make               TIME                                      NOT NULL 
);

CREATE TABLE IF NOT EXISTS Order_log (
    id                         INT           PRIMARY KEY AUTO_INCREMENT  NOT NULL ,
    coffee_name                VARCHAR(255)                              NOT NULL ,
    customer_email             VARCHAR(255)                              NOT NULL ,
    city_name                  VARCHAR(255)                              NOT NULL ,
    sold_at                    DATETIME      DEFAULT CURRENT_TIMESTAMP   NOT NULL ,
    
    FOREIGN KEY (coffee_name  )  REFERENCES Coffee   (name ),
    FOREIGN KEY (customer_email) REFERENCES Customer (email),
    FOREIGN KEY (city_name     ) REFERENCES City     (name )
);



CREATE TABLE IF NOT EXISTS Coffee_update_log (
    id                         INT           PRIMARY KEY AUTO_INCREMENT  NOT NULL ,
    updated_at                 DATETIME      DEFAULT CURRENT_TIMESTAMP   NOT NULL ,
    amount                     BIGINT                                    NOT NULL ,
    customer_email             VARCHAR(255)                              NOT NULL ,
    city_name                  VARCHAR(255)                              NOT NULL ,

    FOREIGN KEY (customer_email) REFERENCES Customer (email),
    FOREIGN KEY (city_name     ) REFERENCES City     (name )
);

CREATE INDEX
    idx_coffee_update_log_customer_city_amount
ON
    Coffee_update_log (customer_email, city_name)
;


CREATE VIEW
    CustomerCoffeeAmount
AS (
    SELECT
        customer_email,
        city_name,
        SUM(amount) AS c_amount
    FROM
        Coffee_update_log
    GROUP BY
        customer_email, city_name
);


DELIMITER $$
CREATE PROCEDURE AddToCustomerCoffee (
    IN customerEmail VARCHAR(255),
    IN cityName      VARCHAR(255),
    IN coffeeToAdd   BIGINT         
)
BEGIN

    INSERT INTO
        Coffee_update_log (customer_email, city_name, amount)
    VALUES
        (customerEmail, cityName, coffeeToAdd)
    ;

END$$
DELIMITER ;


DELIMITER $$
CREATE PROCEDURE SubtractFromCustomerCoffee (
    IN customerEmail      VARCHAR(255),
    IN cityName           VARCHAR(255),
    IN coffeeToSubtract   BIGINT         
)
BEGIN

    CALL AddToCustomerCoffee(customerEmail, cityName, -1 * coffeeToSubtract);

END$$
DELIMITER ;


DELIMITER $$
CREATE TRIGGER pay_trg
BEFORE INSERT ON Order_log FOR EACH ROW
BEGIN

    DECLARE amount_needed BIGINT DEFAULT 0;
    DECLARE current_coffee BIGINT DEFAULT 0;

    SELECT Coffee.amount_needed INTO amount_needed FROM Coffee WHERE Coffee.name = NEW.coffee_name;
    SELECT CustomerCoffeeAmount.c_amount INTO current_coffee FROM CustomerCoffeeAmount WHERE CustomerCoffeeAmount.customer_email = NEW.customer_email and CustomerCoffeeAmount.city_name = NEW.city_name;

    IF current_coffee < amount_needed THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "NOT ENOUGH COFFEE";
    ELSE
        CALL SubtractFromCustomerCoffee(
            NEW.customer_email,
            NEW.city_name,
            amount_needed
        );
    END IF;

END $$
DELIMITER ;


DELIMITER $$
CREATE PROCEDURE OrderCoffee (
    IN customerEmail VARCHAR(255),
    IN cityName      VARCHAR(255),
    IN coffeeName    VARCHAR(255)      
)
BEGIN

    INSERT INTO
        Order_log (coffee_name, city_name, customer_email)
    VALUES
        (coffeeName, cityName, customerEmail)
    ;

END$$
DELIMITER ;




-- Пароли у всех 12345
INSERT INTO
    Customer (email, name, password_hash)
VALUES
    ("alex.alexov@example.com"    , "Alex" , "ba87e41df1e384c857311b7148fbcf388e1b72f58af0080e61f5dcd75fcf8108"),
    ("bob.bobov@example.com"      , "Bob"  , "9f311a0c88436309f99846285ffb795d80cfe000ca60307ee776f649f269a9bb"),
    ("cindy.cindievna@example.com", "Cindy", "c871ffee4c97072c974db6c02a40162652887c07de74a1d7730958f1d4a3448f"),
    ("derek.derekov@example.com"  , "Derek", "388501f8e627e89e87c9012359def682162216ed2c47d95e9c669525e5c7abb4"),
    ("evan.evanov@example.com"    , "Evan" , "efc571ab4b35efd528b4d4ea9bdef9325e0729c36cf9a95f62274bce9cd33b32"),
    ("garry.garry@example.com"    , "Garry", "c118f896da10989a3dab6b42e1bc810bddf6d40ba806c0e6f38c7f48e7b12d03")
;




INSERT INTO
    Coffee (name, amount_needed, time_to_make)
VALUES
    ('Espresso'  , 7 , '00:00:30'),
    ('Latte'     , 10, '00:01:30'),
    ('Cappuccino', 12, '00:02:00'),
    ('Americano' , 8 , '00:01:00'),
    ('Mocha'     , 35, '00:02:30')
;

INSERT INTO
    City (name)
VALUES
    ("Stormwind"),
    ("Ironforge"),
    ("Darnassus")
;





CALL AddToCustomerCoffee('alex.alexov@example.com', 'Stormwind', 100);
CALL AddToCustomerCoffee('alex.alexov@example.com', 'Ironforge', 50);
CALL AddToCustomerCoffee('bob.bobov@example.com', 'Ironforge', 150);
CALL AddToCustomerCoffee('bob.bobov@example.com', 'Darnassus', 75);
CALL AddToCustomerCoffee('cindy.cindievna@example.com', 'Stormwind', 80);
CALL AddToCustomerCoffee('cindy.cindievna@example.com', 'Darnassus', 100);
CALL AddToCustomerCoffee('derek.derekov@example.com', 'Ironforge', 60);
CALL AddToCustomerCoffee('derek.derekov@example.com', 'Stormwind', 120);
CALL AddToCustomerCoffee('evan.evanov@example.com', 'Darnassus', 90);
CALL AddToCustomerCoffee('evan.evanov@example.com', 'Ironforge', 40);
CALL AddToCustomerCoffee('alex.alexov@example.com', 'Stormwind', 30);
CALL AddToCustomerCoffee('bob.bobov@example.com', 'Ironforge', 25);
CALL AddToCustomerCoffee('cindy.cindievna@example.com', 'Darnassus', 45);
CALL AddToCustomerCoffee('derek.derekov@example.com', 'Stormwind', 35);
CALL AddToCustomerCoffee('evan.evanov@example.com', 'Ironforge', 55);
CALL AddToCustomerCoffee('alex.alexov@example.com', 'Ironforge', 20);
CALL AddToCustomerCoffee('bob.bobov@example.com', 'Darnassus', 30);
CALL AddToCustomerCoffee('cindy.cindievna@example.com', 'Stormwind', 10);
CALL AddToCustomerCoffee('derek.derekov@example.com', 'Ironforge', 15);
CALL AddToCustomerCoffee('evan.evanov@example.com', 'Darnassus', 20);

CALL OrderCoffee('alex.alexov@example.com', 'Stormwind', 'Espresso');
CALL OrderCoffee('bob.bobov@example.com', 'Ironforge', 'Latte');
CALL OrderCoffee('cindy.cindievna@example.com', 'Darnassus', 'Cappuccino');
CALL OrderCoffee('evan.evanov@example.com', 'Ironforge', 'Mocha');
CALL OrderCoffee('alex.alexov@example.com', 'Ironforge', 'Espresso');
CALL OrderCoffee('bob.bobov@example.com', 'Darnassus', 'Latte');
CALL OrderCoffee('cindy.cindievna@example.com', 'Stormwind', 'Cappuccino');
CALL OrderCoffee('evan.evanov@example.com', 'Darnassus', 'Mocha');
CALL OrderCoffee('alex.alexov@example.com', 'Stormwind', 'Americano');
CALL OrderCoffee('bob.bobov@example.com', 'Ironforge', 'Espresso');
CALL OrderCoffee('cindy.cindievna@example.com', 'Darnassus', 'Latte');
CALL OrderCoffee('evan.evanov@example.com', 'Ironforge', 'Americano');
CALL OrderCoffee('alex.alexov@example.com', 'Ironforge', 'Mocha');
CALL OrderCoffee('bob.bobov@example.com', 'Darnassus', 'Espresso');
CALL OrderCoffee('cindy.cindievna@example.com', 'Stormwind', 'Latte');
CALL OrderCoffee('evan.evanov@example.com', 'Darnassus', 'Americano');
CALL OrderCoffee('alex.alexov@example.com', 'Stormwind', 'Espresso');
CALL OrderCoffee('bob.bobov@example.com', 'Ironforge', 'Latte');
CALL OrderCoffee('cindy.cindievna@example.com', 'Darnassus', 'Cappuccino');
CALL OrderCoffee('evan.evanov@example.com', 'Ironforge', 'Mocha');
CALL OrderCoffee('alex.alexov@example.com', 'Ironforge', 'Espresso');
CALL OrderCoffee('bob.bobov@example.com', 'Darnassus', 'Latte');
CALL OrderCoffee('cindy.cindievna@example.com', 'Stormwind', 'Cappuccino');
CALL OrderCoffee('evan.evanov@example.com', 'Darnassus', 'Mocha');
CALL OrderCoffee('alex.alexov@example.com', 'Stormwind', 'Americano');
CALL OrderCoffee('bob.bobov@example.com', 'Ironforge', 'Espresso');
CALL OrderCoffee('cindy.cindievna@example.com', 'Darnassus', 'Latte');
CALL OrderCoffee('evan.evanov@example.com', 'Ironforge', 'Americano');
CALL OrderCoffee('alex.alexov@example.com', 'Ironforge', 'Mocha');
CALL OrderCoffee('bob.bobov@example.com', 'Darnassus', 'Espresso');
CALL OrderCoffee('cindy.cindievna@example.com', 'Stormwind', 'Latte');
CALL OrderCoffee('evan.evanov@example.com', 'Darnassus', 'Americano');



CREATE USER 'webapp'@'%' IDENTIFIED BY 'webapppwd';
GRANT SELECT, INSERT, UPDATE, DELETE ON CoffeeDB.* TO 'webapp'@'%';
FLUSH PRIVILEGES;
