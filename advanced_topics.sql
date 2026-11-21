-- Advanced topic: table partitioning
--
-- Train trips, tickets, and payments grow continuously. One large table makes
-- searches, updates, and deletes slower over time. Range partitioning keeps
-- each row in one physical partition, so PostgreSQL reads only the partition
-- that matches the filter (partition pruning) instead of the whole table.
--
-- Train_Trip is partitioned by month on departure_time.
-- Payment is partitioned by year on transaction_date.
-- Ticket is partitioned by ranges of 650 trip ids, about 19,500 tickets each.


-- =============================================================================
-- 1. Train_Trip: monthly partitions on departure_time
-- =============================================================================
--
-- Train_Trip is the central table: departure and arrival, status, train, and
-- the employees who run the trip. New trips are inserted every day, and the
-- usual questions are "trips in this month", "trips in this year", and
-- "delays in this period". departure_time is a natural range key.
-- A monthly partition is about 1/12 of a year, so SELECT, UPDATE, and DELETE
-- touch that slice only.
-- The DEFAULT partition accepts rows whose departure_time falls outside the
-- declared months, so an insert does not fail.

-- Step 1. Keep the existing rows under a new name. Nothing is deleted.
ALTER TABLE "Train Trip" RENAME TO train_trip_old;

-- Step 2. Parent table. It stores no rows itself.
-- departure_time must be part of the primary key because it is the partition key.
-- start_station_id and end_station_id are nullable; the previous table had no
-- such columns, so migrated rows leave them empty.
CREATE TABLE Train_Trip (
    trip_id SERIAL,
    departure_time TIMESTAMP NOT NULL,
    arrival_time TIMESTAMP,
    trip_status VARCHAR(20),
    delay_minutes INT,
    route_id INT NOT NULL,
    train_id INT NOT NULL,
    employee_id INT NOT NULL,
    employee_embg CHAR(13) NOT NULL,
    platform_station_id INT NOT NULL,
    platform_id INT NOT NULL,
    start_station_id INT,
    end_station_id INT,
    PRIMARY KEY (trip_id, departure_time)
) PARTITION BY RANGE (departure_time);

-- Step 3. Safety net for dates outside 2020-01 .. 2030-01.
CREATE TABLE train_trip_default
PARTITION OF train_trip
DEFAULT;

-- Step 4. One partition per month from 2020 through 2029.
-- Names look like train_trip_2020_01. The upper bound is exclusive.
DO $$
DECLARE
    start_date DATE := DATE '2020-01-01';
    end_date   DATE := DATE '2030-01-01';
    part_start DATE;
    part_end   DATE;
    part_name  TEXT;
BEGIN
    part_start := start_date;

    WHILE part_start < end_date LOOP
        part_end := part_start + INTERVAL '1 month';
        part_name := 'train_trip_' || to_char(part_start, 'YYYY_MM');

        EXECUTE format(
            'CREATE TABLE IF NOT EXISTS %I PARTITION OF train_trip
             FOR VALUES FROM (%L) TO (%L)',
            part_name,
            part_start,
            part_end
        );

        part_start := part_end;
    END LOOP;
END $$;

-- Step 5. Confirm the monthly tables exist and are real partitions of train_trip.
SELECT tablename
FROM pg_tables
WHERE tablename LIKE 'train_trip_%'
ORDER BY tablename;

SELECT inhrelid::regclass AS partition
FROM pg_inherits
WHERE inhparent = 'train_trip'::regclass;

-- Step 6. Copy the old rows. NOT EXISTS skips a row that is already loaded.
-- The editor collapsed this select list after arrival_time. The names below
-- are the original "Train Trip" columns, written into the new parent columns.
-- PostgreSQL places each row into the month of its departure_time.
INSERT INTO train_trip (
    trip_id,
    departure_time,
    arrival_time,
    trip_status,
    delay_minutes,
    route_id,
    train_id,
    employee_id,
    employee_embg,
    platform_station_id,
    platform_id
)
SELECT
    o.trip_id,
    o.departure_time,
    o.arrival_time,
    o.trip_status,
    o.delay_minutes,
    o.Routeroute_id,
    o.Traintrain_id,
    o.Employeeemployee_id,
    o.EmployeePersonEMBG2,
    o.PlatformStationstation_id,
    o.Platformplatform_id
FROM train_trip_old o
WHERE NOT EXISTS (
    SELECT 1
    FROM train_trip t
    WHERE t.trip_id = o.trip_id
      AND t.departure_time = o.departure_time
);

-- Same job as the block above, for any later date range the user passes in.
-- p_start_date and p_end_date are inclusive at the start and exclusive at the
-- end of the last month. Existing partitions are left in place (IF NOT EXISTS)
-- and existing rows are not inserted twice.
CREATE OR REPLACE PROCEDURE train_trip_partitions(
    p_start_date DATE,
    p_end_date   DATE
)
LANGUAGE plpgsql
AS $$
DECLARE
    part_start DATE;
    part_end   DATE;
    part_name  TEXT;
BEGIN
    part_start := date_trunc('month', p_start_date)::DATE;

    WHILE part_start < p_end_date LOOP
        part_end := (part_start + INTERVAL '1 month')::DATE;
        part_name := 'train_trip_' || to_char(part_start, 'YYYY_MM');

        EXECUTE format(
            'CREATE TABLE IF NOT EXISTS %I
             PARTITION OF train_trip
             FOR VALUES FROM (%L) TO (%L)',
            part_name,
            part_start,
            part_end
        );

        part_start := part_end;
    END LOOP;

    INSERT INTO train_trip (
        trip_id,
        departure_time,
        arrival_time,
        trip_status,
        delay_minutes,
        route_id,
        train_id,
        employee_id,
        employee_embg,
        platform_station_id,
        platform_id
    )
    SELECT
        o.trip_id,
        o.departure_time,
        o.arrival_time,
        o.trip_status,
        o.delay_minutes,
        o.Routeroute_id,
        o.Traintrain_id,
        o.Employeeemployee_id,
        o.EmployeePersonEMBG2,
        o.PlatformStationstation_id,
        o.Platformplatform_id
    FROM train_trip_old o
    WHERE NOT EXISTS (
        SELECT 1
        FROM train_trip t
        WHERE t.trip_id = o.trip_id
          AND t.departure_time = o.departure_time
    );

    RAISE NOTICE 'Migration completed successfully';
END;
$$;

-- Monthly partitions mean a query for one month reads that month only,
-- which is easier to maintain as the trip history grows.


-- =============================================================================
-- 2. Payment: yearly partitions on transaction_date
-- =============================================================================
--
-- Payment holds every transaction: amount, timestamp, and the reservation.
-- New payments arrive every day, and accounting reports ask for one year.
-- A yearly range lets PostgreSQL ignore every other year, including the
-- disk read, and old years can be archived by detaching one partition.
-- The DEFAULT partition keeps a payment whose timestamp is outside the
-- prepared years, so buying a ticket does not abort.

-- Step 1. Preserve the current financial rows.
ALTER TABLE Payment RENAME TO payment_original;

-- Step 2. Parent table. transaction_date is part of the primary key
-- because a partitioned table requires the partition key in every unique key.
CREATE TABLE Payment (
    payment_id INT NOT NULL,
    amount NUMERIC(10, 2) NOT NULL,
    transaction_date TIMESTAMP NOT NULL,
    Reservationreservation_id INT,
    PRIMARY KEY (payment_id, transaction_date)
) PARTITION BY RANGE (transaction_date);

-- Step 3. One partition per calendar year. The upper bound is exclusive,
-- so a row belongs to exactly one year. Add the same statement for each year.
-- 2025
CREATE TABLE payment_2025 PARTITION OF Payment
    FOR VALUES FROM ('2025-01-01 00:00:00') TO ('2026-01-01 00:00:00');

-- 2026
CREATE TABLE payment_2026 PARTITION OF Payment
    FOR VALUES FROM ('2026-01-01 00:00:00') TO ('2027-01-01 00:00:00');

-- Step 4. Rows outside those years land here instead of raising an error.
CREATE TABLE payment_default PARTITION OF Payment DEFAULT;

-- Step 5. Move the saved payments. PostgreSQL picks the year partition
-- from transaction_date.
INSERT INTO Payment (payment_id, amount, transaction_date, Reservationreservation_id)
SELECT payment_id, amount, transaction_date, Reservationreservation_id
FROM payment_original;

-- A report for one year now reads that year's partition only.


-- =============================================================================
-- 3. Ticket: range partitions on trip id
-- =============================================================================
--
-- Ticket is the heaviest table. Every sold seat is one row, and the volume
-- multiplies because each trip and each payment produces tickets. At the
-- planned size of about 12 million rows, a search that scans the whole table
-- is too slow. Tickets are almost always looked up for one trip (station
-- checks, conductor checks, reservation review), so the partition key is
-- "Train Triptrip_id". One ticket then sits in exactly one partition.
--
-- Sizing, from the monthly trip volume:
--   3,300 trains in a month * 30 tickets = 99,000 tickets that month.
--   99,000 / 20,000 ≈ 5 partitions per month, the target size.
--   3,300 trains / 5 partitions = 660, rounded to 650 trains per partition.
--   650 trains * 30 tickets = 19,500 tickets, close to the 20,000 target.
--   400,000 trips / 650 ≈ 616 partitions (ticket_p_range_0 .. ticket_p_range_615).
-- Trip ids are assigned in order, so a band of 650 ids lines up with a slice
-- of one monthly Train_Trip partition. Joins between tickets and trips can
-- prune both sides.
--
-- payment_transaction_date was added so the foreign key to Payment is
-- (payment_id, transaction_date), the same columns as Payment's primary key.
-- A ticket therefore is not split across two Payment partitions either.

-- Step 1. Keep the generated tickets. The rename does not drop them.
ALTER TABLE Ticket RENAME TO old_ticket;

-- Step 2. Parent table. The partition key is part of the primary key.
-- payment_transaction_date uses the same type as Payment.transaction_date
-- so the composite foreign key is valid.
CREATE TABLE Ticket (
    ticket_id INT NOT NULL,
    seat_number INT,
    carriage_number INT,
    price NUMERIC(5, 2),
    ticket_status VARCHAR(20),
    Paymentpayment_id INT NOT NULL,
    payment_transaction_date TIMESTAMP NOT NULL,
    "Train Triptrip_id" INT NOT NULL,
    Stationstation_id INT NOT NULL,
    Stationstation_id2 INT NOT NULL,
    PRIMARY KEY (ticket_id, "Train Triptrip_id"),
    CONSTRAINT fk_ticket_payment
        FOREIGN KEY (Paymentpayment_id, payment_transaction_date)
        REFERENCES Payment (payment_id, transaction_date),
    CONSTRAINT starts_at
        FOREIGN KEY (Stationstation_id)
        REFERENCES Station (station_id),
    CONSTRAINT ends_at
        FOREIGN KEY (Stationstation_id2)
        REFERENCES Station (station_id)
) PARTITION BY RANGE ("Train Triptrip_id");

-- Step 3. Build the 650-wide ranges up to trip id 400,000.
-- LEAST stops the last partition on max_id + 1 instead of running past it.
-- About 616 partitions, ~19,500 tickets each. Writing them by hand is unnecessary.
DO $$
DECLARE
    start_id   INT := 1;
    step_size  INT := 650;
    max_id     INT := 400000;
    current_id INT := start_id;
    p_counter  INT := 0;
BEGIN
    WHILE current_id <= max_id LOOP
        EXECUTE format(
            'CREATE TABLE ticket_p_range_%s
             PARTITION OF Ticket
             FOR VALUES FROM (%s) TO (%s)',
            p_counter,
            current_id,
            LEAST(current_id + step_size, max_id + 1)
        );

        current_id := current_id + step_size;
        p_counter := p_counter + 1;
    END LOOP;
END $$;

-- Step 4. Reload the saved tickets.
-- payment_transaction_date did not exist on old_ticket, so it is taken from
-- Payment. Rows with no trip id cannot be placed in a range and are skipped.
-- PostgreSQL then routes each row by "Train Triptrip_id".
INSERT INTO Ticket (
    ticket_id,
    seat_number,
    carriage_number,
    price,
    ticket_status,
    Paymentpayment_id,
    payment_transaction_date,
    "Train Triptrip_id",
    Stationstation_id,
    Stationstation_id2
)
SELECT
    t.ticket_id,
    t.seat_number,
    t.carriage_number,
    t.price,
    t.ticket_status,
    t.Paymentpayment_id,
    p.transaction_date,
    t."Train Triptrip_id",
    t.Stationstation_id,
    t.Stationstation_id2
FROM old_ticket t
INNER JOIN Payment p ON t.Paymentpayment_id = p.payment_id
WHERE t."Train Triptrip_id" IS NOT NULL;

-- Step 5. List every partition that actually hangs off ticket.
SELECT
    inhrelid::regclass AS partition_name
FROM pg_inherits
WHERE inhparent = 'ticket'::regclass;

-- About 12 million tickets are split into ~616 partitions of ~19,500 rows.
-- A lookup by trip id opens one partition. The composite foreign key to
-- Payment keeps that same ticket inside one payment partition as well.
