CREATE DATABASE mountaineering_club_db;

CREATE SCHEMA mountaineering_club_schema;


--1 - Climbers
CREATE TABLE IF NOT EXISTS Climbers (
    climber_id SERIAL PRIMARY KEY,
    first_name VARCHAR(25) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    date_of_birth DATE NOT NULL,
    phone_number VARCHAR(18) UNIQUE NOT NULL,
    address_id int NOT NULL
);

ALTER TABLE Climbers
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

--2 - Address
CREATE TABLE IF NOT EXISTS Address (
    address_id SERIAL PRIMARY KEY,
    street VARCHAR(25) NOT NULL,
    city_id int NOT NULL,
    building_number int NOT NULL,
    postal_code int NOT NULL
);

ALTER TABLE Address
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

--3 - City
CREATE TABLE IF NOT EXISTS City (
    city_id SERIAL PRIMARY KEY,
    city_name VARCHAR(20) NOT NULL,
    country_id int NOT NULL
);

ALTER TABLE City
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

--4 - Country
CREATE TABLE IF NOT EXISTS Country (
    country_id SERIAL PRIMARY KEY,
    country_name VARCHAR(25) NOT NULL
);

ALTER TABLE Country
ADD CONSTRAINT unique_country_name UNIQUE (country_name);

ALTER TABLE Country
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

--5 - Clubs
CREATE TABLE IF NOT EXISTS Clubs (
    club_id SERIAL PRIMARY KEY,
    club_name VARCHAR(25) UNIQUE NOT NULL,
    membership_fee DECIMAL(10,2) NULL,
    created_at date NOT NULL 
		CHECK (created_at > DATE '2000-01-01')
);

ALTER TABLE Clubs
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

--6 - Club Climber
CREATE TABLE IF NOT EXISTS Club_Climber (
    club_id int NOT NULL,
    climber_id int NOT NULL
);

ALTER TABLE Club_Climber
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

--7 - Climbs
CREATE TABLE IF NOT EXISTS Climbs (
    climb_id SERIAL PRIMARY KEY,
    mountain_id int NOT NULL,
    start_date date NOT NULL 
		CHECK (start_date > DATE '2000-01-01'),
    end_date date NULL,
    success boolean NOT NULL
);

ALTER TABLE Climbs
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

--8 - Climb Participant
CREATE TABLE IF NOT EXISTS Climb_Participant (
    climb_id int NOT NULL,
    climber_id int NOT NULL
);

ALTER TABLE Climb_Participant
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

--9 - Mountains
CREATE TABLE IF NOT EXISTS Mountains (
    mountain_id SERIAL PRIMARY KEY,
    name VARCHAR(25) UNIQUE NOT NULL,
    height_cm int NOT NULL
);

ALTER TABLE Mountains
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

--10 - Mountain Country
CREATE TABLE IF NOT EXISTS Mountain_Country (
    mountain_id int NOT NULL,
    country_id int NOT NULL
);

ALTER TABLE Mountain_Country
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

--11 - Difficulty
CREATE TABLE IF NOT EXISTS Difficulty (
    mountain_id int NOT NULL,
    difficulty VARCHAR(10) NOT NULL
		CHECK(Difficulty.difficulty IN('Easy', 'Moderate', 'Hard'))
);

ALTER TABLE Difficulty
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

--12 - Equipment
CREATE TABLE IF NOT EXISTS Equipment (
    equipment_id SERIAL PRIMARY KEY,
    name VARCHAR(20) NOT NULL,
    price_per_day DECIMAL NOT NULL
		CHECK(Equipment.price_per_day > 0),
    quantity_available int NULL
		CHECK(quantity_available >= 0),
    type_id int NOT NULL
);

ALTER TABLE Equipment
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

--13 - Equipment Type
CREATE TABLE IF NOT EXISTS Equipment_Type (
    type_id SERIAL PRIMARY KEY,
    type VARCHAR(20) NOT NULL
);

ALTER TABLE Equipment_Type
ADD CONSTRAINT unique_equipment_type UNIQUE (type);

ALTER TABLE Equipment_Type
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

--14 - Climb Equipment
CREATE TABLE IF NOT EXISTS Climb_Equipment (
    climb_id int NOT NULL,
    equipment_id int NOT NULL,
    quantity_used int NOT NULL
);

ALTER TABLE Climb_Equipment
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

--15 - Equipment Rental
CREATE TABLE IF NOT EXISTS Equipment_Rental (
    rental_id SERIAL PRIMARY KEY,
    climber_id int NOT NULL,
    equipment_id int NOT NULL,
    rental_date DATE NOT NULL,
    return_date DATE NULL,
    rental_quantity int NOT NULL
);

ALTER TABLE Equipment_Rental
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

--16 - Payments
CREATE TABLE IF NOT EXISTS Payments (
    payment_id SERIAL PRIMARY KEY,
    climber_id int NOT NULL,
    amount DECIMAL(10,2) NOT NULL
		CHECK(Payments.amount > 0),
    payment_date DATE NOT NULL
		CHECK (Payments.payment_date > DATE '2000-01-01'),
    payment_method_id int NOT NULL,
    status VARCHAR(10) NOT NULL
		CHECK(Payments.status IN('Pending', 'Completed', 'Refunded')),
	booking_id int NULL,
	rental_id int NULL
);

ALTER TABLE Payments
ADD CONSTRAINT payments_check1
CHECK (
  (booking_id IS NOT NULL AND rental_id IS NULL)
  OR
  (booking_id IS NULL AND rental_id IS NOT NULL)
);

ALTER TABLE Payments
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

ALTER TABLE Payments
ADD COLUMN is_successful BOOLEAN GENERATED ALWAYS AS (
    CASE WHEN status = 'Completed' THEN TRUE ELSE FALSE END
) STORED;


--17 - Payment Methods
CREATE TABLE IF NOT EXISTS Payment_Methods (
    method_id SERIAL PRIMARY KEY,
    method VARCHAR(20) NOT NULL
		CHECK(Payment_Methods.method IN('Credit Card', 'Bank Transfer', 'PayPal'))
);

ALTER TABLE Payment_Methods
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

--18 - Service
CREATE TABLE IF NOT EXISTS Service (
    service_id SERIAL PRIMARY KEY,
    service_name VARCHAR(20) NOT NULL,
    description TEXT NULL,
    price DECIMAL(10,2) NOT NULL,
    duration_days int NOT NULL
);

ALTER TABLE Service
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

--19 - Bookings
CREATE TABLE IF NOT EXISTS Bookings (
    booking_id SERIAL PRIMARY KEY,
    climber_id int NOT NULL,
    service_id int NOT NULL,
    booking_date DATE NOT NULL,
    status VARCHAR(10) NOT NULL
		CHECK(Bookings.status IN('Pending', 'Confirmed', 'Cancelled'))
);

ALTER TABLE Bookings
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;



--COMPOSITE PRIMARY KEYS--
--Club_Climber
ALTER TABLE Club_Climber
ADD PRIMARY KEY (club_id, climber_id);

--Climb_Participant
ALTER TABLE Climb_Participant
ADD PRIMARY KEY (climb_id, climber_id);

--Mountain_Country
ALTER TABLE Mountain_Country
ADD PRIMARY KEY (mountain_id, country_id);

--Climb_Equipment
ALTER TABLE Climb_Equipment
ADD PRIMARY KEY (climb_id, equipment_id);



--FOREIGN KEYS--
--Climbers
ALTER TABLE Climbers
ADD CONSTRAINT fk_climbers_address
FOREIGN KEY (address_id)
REFERENCES Address(address_id);

--Address
ALTER TABLE Address
ADD CONSTRAINT fk_address_city
FOREIGN KEY (city_id)
REFERENCES City(city_id);

--City
ALTER TABLE City
ADD CONSTRAINT fk_city_country
FOREIGN KEY (country_id)
REFERENCES Country(country_id);

--Club_Climber
ALTER TABLE Club_Climber
ADD CONSTRAINT fk_club_climber_clubs
FOREIGN KEY (club_id)
REFERENCES Clubs(club_id);

ALTER TABLE Club_Climber
ADD CONSTRAINT fk_club_climber_climbers
FOREIGN KEY (climber_id)
REFERENCES Climbers(climber_id);

--Climbs
ALTER TABLE Climbs
ADD CONSTRAINT fk_climbs_mountains
FOREIGN KEY (mountain_id)
REFERENCES Mountains(mountain_id);

--Climb_Participant
ALTER TABLE Climb_Participant
ADD CONSTRAINT fk_climb_participant_climbs
FOREIGN KEY (climb_id)
REFERENCES Climbs(climb_id);

ALTER TABLE Climb_Participant
ADD CONSTRAINT fk_climb_participant_climbers
FOREIGN KEY (climber_id)
REFERENCES Climbers(climber_id);

--Mountain_Country
ALTER TABLE Mountain_Country
ADD CONSTRAINT fk_mountain_country_mountains
FOREIGN KEY (mountain_id)
REFERENCES Mountains(mountain_id);

ALTER TABLE Mountain_Country
ADD CONSTRAINT fk_mountain_country_country
FOREIGN KEY (country_id)
REFERENCES Country(country_id);

--Difficulty
ALTER TABLE Difficulty
ADD CONSTRAINT fk_difficulty_mountain
FOREIGN KEY (mountain_id)
REFERENCES Mountains(mountain_id);

--Equipment
ALTER TABLE Equipment
ADD CONSTRAINT fk_equipment_type
FOREIGN KEY (type_id)
REFERENCES Equipment_Type(type_id);

--Climb_Equipment
ALTER TABLE Climb_Equipment
ADD CONSTRAINT fk_climb_equipment_climb
FOREIGN KEY (climb_id)
REFERENCES Climbs(climb_id);

ALTER TABLE Climb_Equipment
ADD CONSTRAINT fk_climb_equipment_equipment
FOREIGN KEY (equipment_id)
REFERENCES Equipment(equipment_id);

--Equipment_Rental
ALTER TABLE Equipment_Rental
ADD CONSTRAINT fk_equipment_rental_climber
FOREIGN KEY (climber_id)
REFERENCES Climbers(climber_id);

ALTER TABLE Equipment_Rental
ADD CONSTRAINT fk_equipment_rental_equipment
FOREIGN KEY (equipment_id)
REFERENCES Equipment(equipment_id);

--Payments
ALTER TABLE Payments
ADD CONSTRAINT fk_payment_climber
FOREIGN KEY (climber_id)
REFERENCES Climbers(climber_id);

ALTER TABLE Payments
ADD CONSTRAINT fk_payment_payment_method
FOREIGN KEY (payment_method_id)
REFERENCES Payment_Methods(method_id);

ALTER TABLE Payments
ADD CONSTRAINT fk_payment_booking
FOREIGN KEY (booking_id)
REFERENCES Bookings(booking_id);

ALTER TABLE Payments
ADD CONSTRAINT fk_payment_rental
FOREIGN KEY (rental_id)
REFERENCES Equipment_Rental(rental_id);

--Bookings
ALTER TABLE Bookings
ADD CONSTRAINT fk_booking_climber
FOREIGN KEY (climber_id)
REFERENCES Climbers(climber_id);

ALTER TABLE Bookings
ADD CONSTRAINT fk_booking_service
FOREIGN KEY (service_id)
REFERENCES Service(service_id);



--INSERT TRANSACTION
BEGIN;

--Insert into Country
DO $$
BEGIN
    -- Checking if 'Nepal' already exists in Country table, if not, insert it
    IF NOT EXISTS (SELECT 1 FROM Country WHERE UPPER(country_name) = 'NEPAL') THEN
        INSERT INTO Country (country_name, record_ts)
        VALUES ('Nepal', CURRENT_DATE);
    END IF;
    -- Same logic
    IF NOT EXISTS (SELECT 1 FROM Country WHERE UPPER(country_name) = 'TANZANIA') THEN
        INSERT INTO Country (country_name, record_ts)
        VALUES ('Tanzania', CURRENT_DATE);
    END IF;
END $$;

--Insert into City
DO $$
BEGIN
    -- Checking if 'Kathmandu' already exists in City table, if not, insert it
    IF NOT EXISTS (SELECT 1 FROM City WHERE UPPER(city_name) = 'KATHMANDU') THEN
        INSERT INTO City (city_name, country_id, record_ts)
        VALUES ('Kathmandu', (SELECT country_id FROM Country WHERE UPPER(country_name) = 'NEPAL'), CURRENT_DATE);
    END IF;
    -- Same logic
    IF NOT EXISTS (SELECT 1 FROM City WHERE UPPER(city_name) = 'MOSHI') THEN
        INSERT INTO City (city_name, country_id, record_ts)
        VALUES ('Moshi', (SELECT country_id FROM Country WHERE UPPER(country_name) = 'TANZANIA'), CURRENT_DATE);
    END IF;
END $$;

-- Insert into Address
DO $$
BEGIN
    -- Checking if the address already exists in Address table, if not, insert it
    IF NOT EXISTS (SELECT 1 FROM Address WHERE LOWER(street) = 'thamel') THEN
        INSERT INTO Address (street, city_id, building_number, postal_code, record_ts)
        VALUES ('Thamel', (SELECT city_id FROM City WHERE LOWER(city_name) = 'kathmandu'), 123, 44600, CURRENT_DATE);
    END IF;
    -- Same logic
    IF NOT EXISTS (SELECT 1 FROM Address WHERE LOWER(street) = 'kaunda') THEN
        INSERT INTO Address (street, city_id, building_number, postal_code, record_ts)
        VALUES ('Kaunda', (SELECT city_id FROM City WHERE LOWER(city_name) = 'moshi'), 456, 20020, CURRENT_DATE);
    END IF;
END $$;

--Insert into Climbers
DO $$
BEGIN
    -- Checking if 'Tenzing Norgay' already exists in Climbers table, if not, insert it
    IF NOT EXISTS (SELECT 1 FROM Climbers WHERE UPPER(first_name) = 'TENZING' AND UPPER(last_name) = 'NORGAY') THEN
        INSERT INTO Climbers (first_name, last_name, date_of_birth, phone_number, address_id, record_ts)
        VALUES ('Tenzing', 'Norgay', '1980-05-29', '123456789', (SELECT address_id FROM Address WHERE LOWER(street) = 'thamel'), CURRENT_DATE);
    END IF;
    -- Same logic
    IF NOT EXISTS (SELECT 1 FROM Climbers WHERE first_name = 'Reinhold' AND last_name = 'Messner') THEN
        INSERT INTO Climbers (first_name, last_name, date_of_birth, phone_number, address_id, record_ts)
        VALUES ('Reinhold', 'Messner', '1944-09-17', '987654321', (SELECT address_id FROM Address WHERE LOWER(street) = 'kaunda'), CURRENT_DATE);
    END IF;
END $$;

--Insert into Clubs
DO $$
BEGIN
    -- Checking if 'Himalayan Explorers' already exists in Clubs table, if not, insert it
    IF NOT EXISTS (SELECT 1 FROM Clubs WHERE LOWER(club_name) = 'himalayan explorers') THEN
        INSERT INTO Clubs (club_name, membership_fee, created_at, record_ts)
        VALUES ('Himalayan Explorers', 150.00, '2010-04-15', CURRENT_DATE);
    END IF;
    -- Same logic
    IF NOT EXISTS (SELECT 1 FROM Clubs WHERE LOWER(club_name) = 'mountain adventurers') THEN
        INSERT INTO Clubs (club_name, membership_fee, created_at, record_ts)
        VALUES ('Mountain Adventurers', 120.00, '2015-06-20', CURRENT_DATE);
    END IF;
END $$;

--Insert into Club_Climber
DO $$
BEGIN
    -- Checking if combination of club_id and climber_id already exists in Club_Climber, if not, insert it
    IF NOT EXISTS (SELECT 1 FROM Club_Climber WHERE club_id = 1 AND climber_id = 1) THEN
        INSERT INTO Club_Climber (club_id, climber_id, record_ts)
        VALUES (1, 1, CURRENT_DATE);
    END IF;
    -- Same logic
    IF NOT EXISTS (SELECT 1 FROM Club_Climber WHERE club_id = 2 AND climber_id = 2) THEN
        INSERT INTO Club_Climber (club_id, climber_id, record_ts)
        VALUES (2, 2, CURRENT_DATE);
    END IF;
END $$;

--Insert into Mountains
DO $$
BEGIN
	-- Checking if 'Everest' already exists in Mounatains table, if not, insert it
	IF NOT EXISTS (SELECT 1 FROM Mountains WHERE UPPER(name) = 'MOUNT EVEREST') THEN
		INSERT INTO Mountains (name, height_cm)
		VALUES('Mount Everest', 8849);
	END IF;
	-- Same logic
	IF NOT EXISTS (SELECT 1 FROM Mountains WHERE UPPER(name) = 'MOUNT KILIMANJARO') THEN
		INSERT INTO Mountains (name, height_cm)
		VALUES('Mount Kilimanjaro', 5895);
	END IF; 
END $$;

--Insert into Mountain_Country
DO $$
BEGIN
    -- Checking if combination of mountain_id and country_id already exists in Mountain_Country, if not, insert it
    IF EXISTS (SELECT 1 FROM Mountains WHERE UPPER(name) = 'MOUNT EVEREST') AND EXISTS (SELECT 1 FROM Country WHERE UPPER(country_name) = 'NEPAL') THEN
        INSERT INTO Mountain_Country (mountain_id, country_id)
        VALUES (
            (SELECT mountain_id FROM Mountains WHERE UPPER(name) = 'MOUNT EVEREST'),
            (SELECT country_id FROM Country WHERE UPPER(country_name) = 'NEPAL')
        );
    END IF;
	-- Same logic
	IF EXISTS (SELECT 1 FROM Mountains WHERE UPPER(name) = 'MOUNT KILIMANJARO') AND EXISTS (SELECT 1 FROM Country WHERE UPPER(country_name) = 'TANZANIA') THEN
        INSERT INTO Mountain_Country (mountain_id, country_id)
        VALUES (
            (SELECT mountain_id FROM Mountains WHERE UPPER(name) = 'MOUNT KILIMANJARO'),
            (SELECT country_id FROM Country WHERE UPPER(country_name) = 'TANZANIA')
        );
    END IF;
END $$;

--Insert into Difficulty
DO $$
BEGIN
	-- Checking if mountain with id 1 ('Everest') already exists in Difficulty, if not, insert it
    IF NOT EXISTS (SELECT 1 FROM Difficulty WHERE mountain_id = 1) THEN
        INSERT INTO Difficulty (mountain_id, difficulty)
        VALUES (1, 'Hard');
    END IF;
	-- Same logic
    IF NOT EXISTS (SELECT 1 FROM Difficulty WHERE mountain_id = 2) THEN
        INSERT INTO Difficulty (mountain_id, difficulty)
        VALUES (2, 'Moderate');
    END IF;
END $$;

--Insert into Climbs
DO $$
BEGIN
    -- Checking if 'Mount Everest' climb already exists in Climbs table, if not, insert it
    IF NOT EXISTS (SELECT 1 FROM Climbs WHERE mountain_id = 1 AND success = true) THEN
        INSERT INTO Climbs (mountain_id, start_date, end_date, success, record_ts)
        VALUES (1, '2023-05-15', '2023-06-01', true, CURRENT_DATE);
    END IF;
    -- Same logic
    IF NOT EXISTS (SELECT 1 FROM Climbs WHERE mountain_id = 2 AND success = false) THEN
        INSERT INTO Climbs (mountain_id, start_date, end_date, success, record_ts)
        VALUES (2, '2023-07-10', '2023-07-20', false, CURRENT_DATE);
    END IF;
END $$;

--Insert into Climb_Participant
DO $$
BEGIN
    -- Checking if combination of climb_id and participant_id already exists in Climb_Participant, if not, insert it
    IF NOT EXISTS (SELECT 1 FROM Climb_Participant WHERE climb_id = 1 AND climber_id = 1) THEN
        INSERT INTO Climb_Participant (climb_id, climber_id, record_ts)
        VALUES (1, 1, CURRENT_DATE);
    END IF;
    -- Same logic
    IF NOT EXISTS (SELECT 1 FROM Climb_Participant WHERE climb_id = 2 AND climber_id = 2) THEN
        INSERT INTO Climb_Participant (climb_id, climber_id, record_ts)
        VALUES (2, 2, CURRENT_DATE);
    END IF;
END $$;

--Insert into Equipment_Type
DO $$
BEGIN
	-- Checking if 'Saftey' already exists in Equipment_Type, if not, insert it
    IF NOT EXISTS (SELECT 1 FROM Equipment_Type WHERE LOWER(type) = 'safety') THEN
        INSERT INTO Equipment_Type (type)
        VALUES ('Safety');
    END IF;
	-- Same logic
    IF NOT EXISTS (SELECT 1 FROM Equipment_Type WHERE LOWER(type) = 'climbing') THEN
        INSERT INTO Equipment_Type (type)
        VALUES ('Climbing');
    END IF;
END $$;

--Insert into Equipment
DO $$
BEGIN
	-- Checking if 'Oxygen Tank' already exists in Equipment, if not, insert it
    IF NOT EXISTS (SELECT 1 FROM Equipment WHERE LOWER(name) = 'oxygen tank') THEN
        INSERT INTO Equipment (name, price_per_day, quantity_available, type_id)
        VALUES ('Oxygen Tank', 100.00, 12, 1);
    END IF;
	-- Same logic
    IF NOT EXISTS (SELECT 1 FROM Equipment WHERE LOWER(name) = 'climbing rope') THEN
        INSERT INTO Equipment (name, price_per_day, quantity_available, type_id)
        VALUES ('Climbing Rope', 23.60, 45, 2);
    END IF;
END $$;

--Insert into Climb_Equipment
DO $$
BEGIN
	-- Checking if combination of climb_id and equipment_id already exists in Climb_Equipment, if not, insert it
    IF NOT EXISTS (SELECT 1 FROM Climb_Equipment WHERE climb_id = 1 AND equipment_id = 1) THEN
        INSERT INTO Climb_Equipment (climb_id, equipment_id, quantity_used)
        VALUES ((SELECT climb_id FROM Climbs WHERE mountain_id = 1), 
			(SELECT equipment_id FROM Equipment WHERE LOWER(name) = 'oxygen tank'), 2);
    END IF;
	-- Same logic
    IF NOT EXISTS (SELECT 1 FROM Climb_Equipment WHERE climb_id = 2 AND equipment_id = 2) THEN
        INSERT INTO Climb_Equipment (climb_id, equipment_id, quantity_used)
        VALUES ((SELECT climb_id FROM Climbs WHERE mountain_id = 2),
			(SELECT equipment_id FROM Equipment WHERE LOWER(name) = 'climbing rope'), 1);
    END IF;
END $$;

--Insert into Equipment_Rental
DO $$
BEGIN
    -- Checking if rental for equipment 'Oxygen Tank' exists, if not, insert it
    IF NOT EXISTS (SELECT 1 FROM Equipment_Rental WHERE equipment_id = (SELECT equipment_id FROM Equipment WHERE LOWER(name) = 'oxygen tank') AND rental_date = '2023-05-01') THEN
        INSERT INTO Equipment_Rental (rental_id, climber_id, equipment_id, rental_date, return_date, rental_quantity)
        VALUES (1, 1, (SELECT equipment_id FROM Equipment WHERE name = 'Oxygen Tank'), '2023-05-01', '2023-05-15', 2);
    END IF;
    -- Same logic
    IF NOT EXISTS (SELECT 1 FROM Equipment_Rental WHERE equipment_id = (SELECT equipment_id FROM Equipment WHERE LOWER(name) = 'climbing rope') AND rental_date = '2023-06-01') THEN
        INSERT INTO Equipment_Rental (rental_id, climber_id, equipment_id, rental_date, return_date, rental_quantity)
        VALUES (2, 2, (SELECT equipment_id FROM Equipment WHERE name = 'Climbing Rope'), '2023-06-01', '2023-06-10', 1);
    END IF;
END $$;

--Insert into Service
DO $$
BEGIN
    -- Checking if 'Climbing Gear Rental' service exists, if not, insert it
    IF NOT EXISTS (SELECT 1 FROM Service WHERE LOWER(service_name) = 'climbing gear rental') THEN
        INSERT INTO Service (service_name, description, price, duration_days)
        VALUES ('Climbing Gear Rental', 
			'The "Climbing Gear Rental" service offers climbers the option to rent essential climbing equipment, 
			such as ropes, harnesses, and helmets, ensuring they have access to high-quality gear without the need 
			for a large upfront investment.', 
			135.00, 10);
    END IF;
    -- Same logic
    IF NOT EXISTS (SELECT 1 FROM Service WHERE LOWER(service_name) = 'guided tour') THEN
        INSERT INTO Service (service_name, price, duration_days)
        VALUES ('Guided Tour', 230.00, 1);
    END IF;
END $$;

--Inser into Bookings
DO $$
BEGIN
    -- Checking if 'Climbing Gear Rental' already exists for climber 1, if not, insert it
    IF NOT EXISTS (SELECT 1 FROM Bookings WHERE climber_id = 1 AND service_id = (SELECT service_id FROM Service WHERE LOWER(service_name) = 'climbing gear rental')) THEN
        INSERT INTO Bookings (climber_id, service_id, booking_date, status)
        VALUES (1, (SELECT service_id FROM Service WHERE service_name = 'Climbing Gear Rental'), '2023-05-01', 'Cancelled');
    END IF;
	-- Same logic
    IF NOT EXISTS (SELECT 1 FROM Bookings WHERE climber_id = 2 AND service_id = (SELECT service_id FROM Service WHERE LOWER(service_name) = 'guided tour')) THEN
        INSERT INTO Bookings (climber_id, service_id, booking_date, status)
        VALUES (2, (SELECT service_id FROM Service WHERE LOWER(service_name) = 'guided tour'), '2023-06-01', 'Confirmed');
    END IF;
END $$;

--Insert into Payment_Methods
DO $$
BEGIN
    -- Checking if 'Credit Card' already exists in Payment_Methods, if not, insert it
    IF NOT EXISTS (SELECT 1 FROM Payment_Methods WHERE LOWER(method) = 'credit card') THEN
        INSERT INTO Payment_Methods (method_id, method)
        VALUES (1, 'Credit Card');
    END IF;
    -- Same logic
    IF NOT EXISTS (SELECT 1 FROM Payment_Methods WHERE LOWER(method) = 'paypal') THEN
        INSERT INTO Payment_Methods (method_id, method)
        VALUES (2, 'PayPal');
    END IF;
END $$;

--Insert into Payments
DO $$
BEGIN
    -- Checking if payment from climber 1 exists for amount 1000, if not, insert it
    IF NOT EXISTS (SELECT 1 FROM Payments WHERE climber_id = 1 AND amount = 1000) THEN
        INSERT INTO Payments (climber_id, amount, payment_date, payment_method_id, status, rental_id)
        VALUES (1, 1000, '2023-05-15', 1, 'Completed', 1);
    END IF;
    -- Same logice
    IF NOT EXISTS (SELECT 1 FROM Payments WHERE climber_id = 2 AND amount = 1200) THEN
        INSERT INTO Payments (climber_id, amount, payment_date, payment_method_id, status, booking_id)
        VALUES (2, 1200, '2023-06-20', 2, 'Refunded', 1);
    END IF;
END $$;

--Commit transaction
COMMIT;