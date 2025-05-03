--Create the new database and a new schema
CREATE DATABASE household_appliances_store;

CREATE SCHEMA appliances_store;

--Create Tables

--Supplier Table
CREATE TABLE IF NOT EXISTS appliances_store.supplier (
    supplier_id SERIAL PRIMARY KEY,
    supplier_name VARCHAR(50) NOT NULL,
    contact_email VARCHAR(50),
    phone_number VARCHAR(30)
);

--Product Table
CREATE TABLE IF NOT EXISTS appliances_store.product (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(50) NOT NULL,
    brand VARCHAR(50) NOT NULL,
    model VARCHAR(50),
    category VARCHAR(50) NOT NULL,
    price NUMERIC(10,2) NOT NULL
);

--Employee Table
CREATE TABLE IF NOT EXISTS appliances_store.employee (
    employee_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(50) UNIQUE NOT NULL,
    phone_number VARCHAR(50) NOT NULL,
    position VARCHAR(50)
);

--Customer Table
CREATE TABLE IF NOT EXISTS appliances_store.customer (
    customer_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(50) UNIQUE NOT NULL,
    phone_number VARCHAR(50) NOT NULL,
    created_at DATE DEFAULT CURRENT_DATE
);

--Inventory Table
CREATE TABLE IF NOT EXISTS appliances_store.inventory (
    inventory_id SERIAL PRIMARY KEY,
    supplier_id INT NOT NULL,
    product_id INT NOT NULL,
    stock_in INT DEFAULT 0,
    updated_at DATE DEFAULT CURRENT_DATE,
    FOREIGN KEY (supplier_id) REFERENCES appliances_store.supplier(supplier_id),
    FOREIGN KEY (product_id) REFERENCES appliances_store.product(product_id)    
);

--Orders Table
CREATE TABLE IF NOT EXISTS appliances_store.orders (
    order_id SERIAL PRIMARY KEY,
    order_date DATE DEFAULT CURRENT_DATE,
    employee_id INT NOT NULL,
    customer_id INT NOT NULL,
    order_status VARCHAR(20),
    FOREIGN KEY (employee_id) REFERENCES appliances_store.employee(employee_id),
    FOREIGN KEY (customer_id) REFERENCES appliances_store.customer(customer_id)
);

--Order_Item Table
CREATE TABLE IF NOT EXISTS appliances_store.order_item (
    product_id INT NOT NULL,
    order_id INT NOT NULL,
    quantity INT NOT NULL,
    PRIMARY KEY (product_id, order_id),
    FOREIGN KEY (product_id) REFERENCES appliances_store.product(product_id),
    FOREIGN KEY (order_id) REFERENCES appliances_store.orders(order_id)
);


--CHECK CONSTRAINTS

--CHECK that price must be greater than 0
ALTER TABLE appliances_store.product
ADD CONSTRAINT chk_product_price CHECK (price > 0);

--CHECK that created_at must not be a future date
ALTER TABLE appliances_store.customer
ADD CONSTRAINT chk_customer_created_at CHECK (created_at <= CURRENT_DATE);

--CHECK that employee position must be one of specific roles
ALTER TABLE appliances_store.employee
ADD CONSTRAINT chk_employee_position CHECK (position IN ('Sales Assistant', 'Cashier', 'Manager'));

--HECK that stock_in cannot be negative
ALTER TABLE appliances_store.inventory
ADD CONSTRAINT chk_inventory_stock CHECK (stock_in >= 0);

--CHECK that updated_at must be after Jan 1, 2024
ALTER TABLE appliances_store.inventory
ADD CONSTRAINT chk_inventory_updated CHECK (updated_at >= '2024-01-01');

--CHECK that order status must be one of the specific statuses
ALTER TABLE appliances_store.orders
ADD CONSTRAINT chk_order_status CHECK (order_status IN ('Pending', 'Shipped', 'Delivered'));

--CHECK that quantity must be greater than 0
ALTER TABLE appliances_store.order_item
ADD CONSTRAINT chk_orderitem_quantity CHECK (quantity > 0);

--ALTER TABLE appliances_store.employee to create a new column for full name of the employee
ALTER TABLE appliances_store.employee
ADD COLUMN full_name VARCHAR(101) GENERATED ALWAYS AS (first_name || ' ' || last_name) STORED;



--INSERT DATA INTO TABLES

--Supplier
INSERT INTO appliances_store.supplier (supplier_name, contact_email, phone_number) 
VALUES
	('ElectroMax', 'contact@electromax.com', '555-1234'),
	('HomeTech', 'info@hometech.com', '555-5678'),
	('ApplianceWorld', 'sales@applianceworld.com', '555-9012'),
	('PowerHouse', 'support@powerhouse.com', '555-3456'),
	('SmartLiving', 'hello@smartliving.com', '555-7890'),
	('GadgetPros', 'team@gadgetpros.com', '555-2345');

--Product
INSERT INTO appliances_store.product (product_name, brand, model, category, price)
VALUES
	('Washing Machine', 'LG', 'TWINWash', 'Laundry', 799.99),
	('Refrigerator', 'Samsung', 'FamilyHub', 'Kitchen', 1199.99),
	('Microwave Oven', 'Panasonic', 'NN-SN966S', 'Kitchen', 249.50),
	('Dishwasher', 'Bosch', '800 Series', 'Kitchen', 950.00),
	('Vacuum Cleaner', 'Dyson', 'V11 Torque Drive', 'Cleaning', 599.99),
	('Air Conditioner', 'Daikin', 'FTKF50TV', 'Cooling', 899.00);

--Employee
INSERT INTO appliances_store.employee (first_name, last_name, email, phone_number, position) 
VALUES
	('Alice', 'Johnson', 'alice.j@store.com', '555-1111', 'Sales Assistant'),
	('Bob', 'Smith', 'bob.s@store.com', '555-2222', 'Cashier'),
	('Carol', 'Taylor', 'carol.t@store.com', '555-3333', 'Manager'),
	('David', 'Brown', 'david.b@store.com', '555-4444', 'Sales Assistant'),
	('Eva', 'Davis', 'eva.d@store.com', '555-5555', 'Cashier'),	
	('Frank', 'Wilson', 'frank.w@store.com', '555-6666', 'Manager');

--Customer
INSERT INTO appliances_store.customer (first_name, last_name, email, phone_number, created_at) 
VALUES
	('George', 'Harris', 'george.h@client.com', '666-1111', '2025-02-12'),
	('Hannah', 'Martin', 'hannah.m@client.com', '666-2222', '2025-03-15'),
	('Ian', 'Clark', 'ian.c@client.com', '666-3333', '2025-04-01'),
	('Julia', 'Lewis', 'julia.l@client.com', '666-4444', '2025-02-25'),
	('Kevin', 'Walker', 'kevin.w@client.com', '666-5555', '2025-03-18'),
	('Laura', 'Hall', 'laura.h@client.com', '666-6666', '2025-04-05');

--Inventory
INSERT INTO appliances_store.inventory (supplier_id, product_id, stock_in, updated_at)
VALUES 
(
    (SELECT supplier_id FROM appliances_store.supplier WHERE supplier_name = 'ElectroMax'),
    (SELECT product_id FROM appliances_store.product WHERE product_name = 'Washing Machine'),
    30,
    '2025-02-20'
),
(
    (SELECT supplier_id FROM appliances_store.supplier WHERE supplier_name = 'HomeTech'),
    (SELECT product_id FROM appliances_store.product WHERE product_name = 'Refrigerator'),
    20,
    '2025-03-05'
),
(
    (SELECT supplier_id FROM appliances_store.supplier WHERE supplier_name = 'ApplianceWorld'),
    (SELECT product_id FROM appliances_store.product WHERE product_name = 'Microwave Oven'),
    25,
    '2025-04-10'
),
(
    (SELECT supplier_id FROM appliances_store.supplier WHERE supplier_name = 'PowerHouse'),
    (SELECT product_id FROM appliances_store.product WHERE product_name = 'Dishwasher'),
    15,
    '2025-03-22'
),
(
    (SELECT supplier_id FROM appliances_store.supplier WHERE supplier_name = 'SmartLiving'),
    (SELECT product_id FROM appliances_store.product WHERE product_name = 'Vacuum Cleaner'),
    40,
    '2025-02-28'
),
(
    (SELECT supplier_id FROM appliances_store.supplier WHERE supplier_name = 'GadgetPros'),
    (SELECT product_id FROM appliances_store.product WHERE product_name = 'Air Conditioner'),
    10,
    '2025-04-08'
);

--Orders
INSERT INTO appliances_store.orders (order_date, employee_id, customer_id, order_status)
VALUES 
(
    '2025-02-15',
    (SELECT employee_id FROM appliances_store.employee WHERE email = 'alice.j@store.com'),
    (SELECT customer_id FROM appliances_store.customer WHERE email = 'george.h@client.com'),
    'Pending'
),
(
    '2025-03-10',
    (SELECT employee_id FROM appliances_store.employee WHERE email = 'bob.s@store.com'),
    (SELECT customer_id FROM appliances_store.customer WHERE email = 'hannah.m@client.com'),
    'Shipped'
),
(
    '2025-04-01',
    (SELECT employee_id FROM appliances_store.employee WHERE email = 'carol.t@store.com'),
    (SELECT customer_id FROM appliances_store.customer WHERE email = 'ian.c@client.com'),
    'Delivered'
),
(
    '2025-02-20',
    (SELECT employee_id FROM appliances_store.employee WHERE email = 'david.b@store.com'),
    (SELECT customer_id FROM appliances_store.customer WHERE email = 'julia.l@client.com'),
    'Pending'
),
(
    '2025-03-25',
    (SELECT employee_id FROM appliances_store.employee WHERE email = 'eva.d@store.com'),
    (SELECT customer_id FROM appliances_store.customer WHERE email = 'kevin.w@client.com'),
    'Shipped'
),
(
    '2025-04-15',
    (SELECT employee_id FROM appliances_store.employee WHERE email = 'frank.w@store.com'),
    (SELECT customer_id FROM appliances_store.customer WHERE email = 'laura.h@client.com'),
    'Delivered'
);

--Order_Item
INSERT INTO appliances_store.order_item (product_id, order_id, quantity)
VALUES 
(
    (SELECT product_id FROM appliances_store.product WHERE product_name = 'Washing Machine'),
    (SELECT order_id FROM appliances_store.orders 
     WHERE customer_id = (SELECT customer_id FROM appliances_store.customer WHERE email = 'george.h@client.com')),
    2
),
(
    (SELECT product_id FROM appliances_store.product WHERE product_name = 'Refrigerator'),
    (SELECT order_id FROM appliances_store.orders 
     WHERE customer_id = (SELECT customer_id FROM appliances_store.customer WHERE email = 'hannah.m@client.com')),
    1
),
(
    (SELECT product_id FROM appliances_store.product WHERE product_name = 'Microwave Oven'),
    (SELECT order_id FROM appliances_store.orders 
     WHERE customer_id = (SELECT customer_id FROM appliances_store.customer WHERE email = 'ian.c@client.com')),
    1
),
(
    (SELECT product_id FROM appliances_store.product WHERE product_name = 'Dishwasher'),
    (SELECT order_id FROM appliances_store.orders 
     WHERE customer_id = (SELECT customer_id FROM appliances_store.customer WHERE email = 'julia.l@client.com')),
    1
),
(
    (SELECT product_id FROM appliances_store.product WHERE product_name = 'Vacuum Cleaner'),
    (SELECT order_id FROM appliances_store.orders 
     WHERE customer_id = (SELECT customer_id FROM appliances_store.customer WHERE email = 'kevin.w@client.com')),
    2
),
(
    (SELECT product_id FROM appliances_store.product WHERE product_name = 'Air Conditioner'),
    (SELECT order_id FROM appliances_store.orders 
     WHERE customer_id = (SELECT customer_id FROM appliances_store.customer WHERE email = 'laura.h@client.com')),
    1
),
(
    (SELECT product_id FROM appliances_store.product WHERE product_name = 'Refrigerator'),
    (SELECT order_id FROM appliances_store.orders 
     WHERE customer_id = (SELECT customer_id FROM appliances_store.customer WHERE email = 'george.h@client.com')),
    1
),
(
    (SELECT product_id FROM appliances_store.product WHERE product_name = 'Vacuum Cleaner'),
    (SELECT order_id FROM appliances_store.orders 
     WHERE customer_id = (SELECT customer_id FROM appliances_store.customer WHERE email = 'hannah.m@client.com')),
    3
);



--FUNCTIONS

--1
CREATE OR REPLACE FUNCTION appliances_store.update_employee_column(
    employee_id INT,
    column_name TEXT,
    new_value TEXT
)
RETURNS VOID AS
$$
BEGIN
    EXECUTE format(
        'UPDATE appliances_store.employee SET %I = $1 WHERE employee_id = $2',
        column_name
    )
    USING new_value, employee_id;
END;
$$ LANGUAGE plpgsql;


--2
CREATE OR REPLACE FUNCTION appliances_store.create_new_order(
    order_date DATE,
    employee_email TEXT,
    customer_email TEXT,
    order_status TEXT
)
RETURNS VOID AS
$$
DECLARE
    employee_id INT;
    customer_id INT;
BEGIN
    -- Find the employee_id
    SELECT e.employee_id INTO employee_id
    FROM appliances_store.employee e
    WHERE e.email = employee_email;

    -- Find the customer_id
    SELECT c.customer_id INTO customer_id
    FROM appliances_store.customer c
    WHERE c.email = customer_email;

    -- Insert the order
    INSERT INTO appliances_store.orders (order_date, employee_id, customer_id, order_status)
    VALUES (order_date, employee_id, customer_id, order_status);

    RAISE NOTICE 'Order successfully created.';
END;
$$ LANGUAGE plpgsql;



--VIEW
CREATE OR REPLACE VIEW appliances_store.quarterly_sales_analytics AS
SELECT
    o.order_date,
    c.first_name || ' ' || c.last_name AS customer_name,
    e.full_name AS employee_name,
    p.product_name,
    oi.quantity,
    p.price,
    (oi.quantity * p.price) AS total_value,
    o.order_status
FROM
    appliances_store.orders o
INNER JOIN appliances_store.customer c ON o.customer_id = c.customer_id
INNER JOIN appliances_store.employee e ON o.employee_id = e.employee_id
INNER JOIN appliances_store.order_item oi ON o.order_id = oi.order_id
INNER JOIN appliances_store.product p ON oi.product_id = p.product_id
WHERE
    o.order_date >= date_trunc('quarter', CURRENT_DATE) -- start of the last quarter
    AND o.order_date < date_trunc('quarter', CURRENT_DATE) + INTERVAL '3 months'; -- end of the quarter

    
--Create the role
CREATE ROLE manager_role LOGIN PASSWORD 'Login_Password';

--Grant connect to the role
GRANT CONNECT ON DATABASE household_appliances_store TO manager_role;

--Grant usage so that the user can access the schema objects
GRANT USAGE ON SCHEMA appliances_store TO manager_role;

--Grant select privilige to the user on all tables
GRANT SELECT ON ALL TABLES IN SCHEMA appliances_store TO manager_role;
