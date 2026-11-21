-------EMPLOYEE-----------
INSERT INTO employee (personembg, position, companycompany_id)
SELECT
    embg,
    (ARRAY['TrainDriver','AssistantDriver','Conductor','SignalOperator',
           'MaintenanceWorker','StationMaster','Chef','Waiter','Cashier'])
           [(row_num % 9) + 1],
    ((row_num % 4) + 1) AS company_id
FROM (
    SELECT
        embg,
        row_number() OVER (ORDER BY random()) as row_num
    FROM person
    LIMIT 30000
) sorted_people;

select count(*) from employee;
select * from employee limit 1000;


---------PASSENGER---------------------

INSERT INTO passenger (PersonEMBG, passenger_id)
SELECT
    p.embg,
    row_number() OVER (ORDER BY random()) as passenger_id
FROM Person p
LEFT JOIN Employee e ON p.embg = e.personembg
WHERE e.personembg IS NULL
ORDER BY random()
LIMIT 800000;

select count(*) from passenger;
select * from passenger limit 1000;


------------RESERVATION------------------------

TRUNCATE TABLE Reservation RESTART identity cascade;

INSERT INTO Reservation (status, expiry_time, Passengerpassenger_id, PassengerPersonEMBG2)
SELECT
    (ARRAY['Confirmed', 'Pending', 'Cancelled', 'Expired', 'Checked-in'])
    [(s.i % 5) + 1],
        CURRENT_DATE + (floor(random() * 180))::int,
        p.passenger_id,
    p.PersonEMBG
FROM generate_series(1, 3000000) s(i)
JOIN Passenger p ON p.passenger_id = ((s.i % 800000) + 1);

select count(*) from reservation;
select * from reservation limit 1000;


-------------PAYMENT-------------------------
ALTER TABLE payment
ALTER COLUMN amount TYPE NUMERIC(10, 2);

ALTER TABLE payment
ALTER COLUMN transaction_date TYPE TIMESTAMP;


--CREATE INDEX idx_payment_reservation_id ON Payment(Reservationreservation_id);
--CREATE INDEX idx_payment_date ON Payment(transaction_date);

ALTER TABLE payment ALTER COLUMN reservationreservation_id DROP NOT NULL;

TRUNCATE TABLE payment RESTART identity cascade;

INSERT INTO payment (payment_method, amount, transaction_date, reservationreservation_id, passengerpassenger_id, passengerpersonembg2)
SELECT
    (ARRAY['Credit Card', 'Debit Card', 'PayPal', 'Cash', 'Apple Pay'])[floor(random() * 5 + 1)],
    (random() * 140 + 10)::numeric(10,2),
    (expiry_time::timestamp - (random() * interval '5 days')) + (random() * interval '24 hours'),
    reservation_id,
    passengerpassenger_id,
    passengerpersonembg2
FROM reservation;

INSERT INTO payment (payment_method, amount, transaction_date, reservationreservation_id, passengerpassenger_id, passengerpersonembg2)
SELECT
    (ARRAY['Credit Card', 'Debit Card', 'PayPal', 'Cash', 'Apple Pay'])[floor(random() * 5 + 1)],
    (random() * 140 + 10)::numeric(10,2),
    NOW() - (random() * interval '180 days'),
    NULL,
    p.passenger_id,
    p.PersonEMBG
FROM generate_series(1, 9000000) s(i)
JOIN Passenger p ON p.passenger_id = ((s.i % 800000) + 1);

select count(*) from payment;
select * from payment limit 1000;


--------ROUTE----------------

ALTER TABLE Route
ALTER COLUMN route_name TYPE VARCHAR(100);


TRUNCATE TABLE Route RESTART identity cascade;

INSERT INTO Route (route_name, type)
SELECT
    start_city || ' - ' || end_city,
    (floor(random() * 3) + 1)::int
FROM (
    SELECT
        a.city AS start_city,
        b.city AS end_city
    FROM (
        VALUES
        ('Rome'), ('Milan'), ('Naples'), ('Turin'), ('Palermo'), ('Genoa'),
        ('Bologna'), ('Florence'), ('Bari'), ('Catania'), ('Venice'), ('Verona'),
        ('Messina'), ('Trieste'), ('Taranto'), ('Prato'), ('Modena'), ('Parma'),
        ('Reggio Emilia'), ('Perugia'), ('Livorno'), ('Ravenna'), ('Foggia'),
        ('Rimini'), ('Salerno'), ('Ferrara'), ('Sassari'), ('Latina'),
        ('Giugliano'), ('Monza'), ('Siracusa'), ('Pescara')
    ) AS a(city)
    CROSS JOIN (
        VALUES
        ('Rome'), ('Milan'), ('Naples'), ('Turin'), ('Palermo'), ('Genoa'),
        ('Bologna'), ('Florence'), ('Bari'), ('Catania'), ('Venice'), ('Verona'),
        ('Messina'), ('Trieste'), ('Taranto'), ('Prato'), ('Modena'), ('Parma'),
        ('Reggio Emilia'), ('Perugia'), ('Livorno'), ('Ravenna'), ('Foggia'),
        ('Rimini'), ('Salerno'), ('Ferrara'), ('Sassari'), ('Latina'),
        ('Giugliano'), ('Monza'), ('Siracusa'), ('Pescara')
    ) AS b(city)
    WHERE a.city <> b.city
    ORDER BY random()
    LIMIT 1000
) AS combinations;

select count(*) from route;
select * from route limit 300;


--------Employee_performs_maintenance---------------
TRUNCATE TABLE employee_performs_maintenance cascade ;

INSERT INTO employee_performs_maintenance (employeeemployee_id, employeepersonembg2, maintenancemaintenance_id)
SELECT
    e.employee_id,
    e.personembg,
    m.maintenance_id
FROM maintenance m
CROSS JOIN LATERAL (
    SELECT employee_id, personembg
    FROM employee
    WHERE position = 'MaintenanceWorker'
    ORDER BY m.maintenance_id, random()
    LIMIT (floor(random() * 3) + 1)::int
) e;


select count(*) from employee_performs_maintenance;
select * from employee_performs_maintenance limit 1000;
TRUNCATE TABLE employee_performs_maintenance;

SELECT *
FROM employee
WHERE position = 'MaintenanceWorker';

---------train_undergoes_maintenance-------------------

truncate table train_undergoes_maintenance


INSERT INTO train_undergoes_maintenance (traintrain_id, maintenancemaintenance_id)
SELECT DISTINCT
    t.train_id,
    m.maintenance_id
FROM (
    SELECT maintenance_id, random() as rnd FROM maintenance
) m
JOIN LATERAL (
    SELECT train_id
    FROM train
    WHERE m.rnd = m.rnd
    ORDER BY random()
    LIMIT (floor(random() * 2) + 1)::int
) t ON TRUE
ON CONFLICT DO NOTHING;


select count(*) from train_undergoes_maintenance;
select * from train_undergoes_maintenance limit 1000;


/*company*/
----------------------------------------------
INSERT INTO company (company_id, name, contact_info)
VALUES
(1, 'Trenitalia', '+39 06 5210550 | info@trenitalia.it'),
(2, 'Italo', '+39 89 20 20 | ufficiostampa@ntvspa.it'),
(3, 'Trenord', '+39 02 72494949 | support@trenord.it'),
(4, 'EAV', '+39 081 7722444 | info@eavsrl.it');
-------------------------------------------------------

/*train*/

INSERT INTO Train (
    train_number,
    type,
    manufacture_year,
    capacity,
    max_speed,
    Companycompany_id,
    Routeroute_id
)
SELECT
    (1000 + s.i)::int,
    (ARRAY['Freight', 'Passenger', 'High-Speed', 'Commuter', 'Monorail', 'Maglev', 'Subway', 'Intercity'])[floor(random() * 8 + 1)],
    (floor(random() * (2026 - 2010 + 1)) + 2010)::text,
    floor(random() * 400 + 50)::int,
    floor(random() * 200 + 100)::int,
    (SELECT company_id FROM Company
     WHERE (s.i * 0) = 0
     ORDER BY random() LIMIT 1),
    (SELECT route_id FROM Route
     WHERE (s.i * 0) = 0
     ORDER BY random() LIMIT 1)
FROM generate_series(1, 2500) AS s(i);
select * from train limit 1000;

TRUNCATE TABLE train RESTART identity cascade;

-------------------------------------------------------
/*station*/
ALTER TABLE station ALTER COLUMN station_name TYPE VARCHAR(100);
ALTER TABLE station ALTER COLUMN city TYPE VARCHAR(50);


INSERT INTO station (station_name, country, city, address)
SELECT
    city_name || ' ' || secondary_name AS station_name,
    'Italy' AS country,
    city_name,
    'Via ' || secondary_name || ', ' || (floor(random() * 150) + 1) AS address
FROM (
    SELECT
        c.city_name,
        s.secondary_name,
        row_number() OVER (ORDER BY c.city_name, s.secondary_name) as rn
    FROM (
        VALUES
            ('Rome'), ('Milan'), ('Naples'), ('Turin'), ('Palermo'), ('Genoa'),
            ('Bologna'), ('Florence'), ('Bari'), ('Catania'), ('Venice'), ('Verona'),
            ('Messina'), ('Trieste'), ('Taranto'), ('Prato'), ('Modena'), ('Parma'),
            ('Reggio Emilia'), ('Perugia'), ('Livorno'), ('Ravenna'), ('Foggia'),
            ('Rimini'), ('Salerno'), ('Ferrara'), ('Sassari'), ('Latina'),
            ('Giugliano'), ('Monza'), ('Siracusa'), ('Pescara')
    ) AS c(city_name)
    CROSS JOIN (
        VALUES
            ('Centrale'), ('Porta Nuova'), ('Porta Susa'), ('Tiburtina'), ('Ostiense'),
            ('Trastevere'), ('Garibaldi'), ('Brignole'), ('Principe'), ('Mestre'),
            ('Santa Lucia'), ('Campo di Marte'), ('Rifredi'), ('Lambrate'), ('Rogoredo'),
            ('Greco Pirelli'), ('San Pietro'), ('Trionfale'), ('Monte Mario'), ('Nomentana'),
            ('Fiumicino'), ('Lido'), ('Ciampino'), ('Aeroporto'), ('Zona Industriale'),
            ('Porto'), ('Quartiere Ovest'), ('Quartiere Est'), ('Viale Europa'), ('Corso Italia'),
            ('San Giovanni'), ('Santa Maria'), ('San Paolo'), ('Borgo'), ('Rione'),
            ('Piazza Dante'), ('Via Roma'), ('Porta Vecchia'), ('Belvedere'), ('Miramare'),
            ('Villaggio'), ('Parco'), ('Giardino'), ('Scalo'), ('Interporto'),
            ('Terminal A'), ('Terminal B'), ('Terminal Cargo'), ('Semaforo'), ('Bivio'),
            ('Raccordo'), ('Sosta'), ('Deposito'), ('Officine'), ('Sottostazione'),
            ('Posto di Movimento'), ('Fermata'), ('Punto Sosta'), ('Capolinea'), ('Nodo'),
            ('San Nicola'), ('Santa Chiara'), ('Vescovado'), ('Duomo'), ('Castello'),
            ('Torre'), ('Mura'), ('Bastione'), ('Arco'), ('Fontana')
    ) AS s(secondary_name)
) AS final
WHERE rn <= 2200;

select * from station limit 1000;
select count(*) from station;

TRUNCATE TABLE station RESTART identity cascade;

-------------------------------------------------------
/*segment*/

WITH base AS (
    SELECT
        s.station_id,
        gs.p_idx
    FROM station s
    CROSS JOIN generate_series(1, 2) gs(p_idx)
),
shuffled AS (
    SELECT *,
           row_number() OVER (ORDER BY p_idx, random()) AS rn
    FROM base
)
INSERT INTO segment (length_km, type, max_speed, status, stationstation_id3)
SELECT
    (random() * 98 + 1)::numeric(5,2),
    (ARRAY['Standard', 'High-Speed', 'Tunnel', 'Bridge', 'Urban', 'Mountain'])[floor(random() * 6 + 1)],
    (floor(random() * 181) + 60)::int,
    (ARRAY['Active', 'Maintenance', 'Inactive', 'Under Construction'])[floor(random() * 4 + 1)],
    station_id
FROM shuffled
WHERE rn <= 5000;
select count(*) from segment;
select * from segment limit 1000;

INSERT INTO segment (length_km, type, max_speed, status, stationstation_id3)
SELECT
    (random() * 98 + 1)::numeric(5,2),
    (ARRAY['Standard', 'High-Speed', 'Tunnel', 'Bridge', 'Urban', 'Mountain'])[floor(random() * 6 + 1)],
    (floor(random() * 181) + 60)::int,
    (ARRAY['Active', 'Maintenance', 'Inactive', 'Under Construction'])[floor(random() * 4 + 1)],
    station_id
FROM (
    SELECT station_id
    FROM station
    ORDER BY random()
    LIMIT 600
) sub;

SELECT
    (SELECT COUNT(*) FROM segment) as vkupno_segmenti,
    (SELECT COUNT(DISTINCT stationstation_id3) FROM segment) as pokrieni_stanici;

UPDATE Segment s
SET
    start_station_id = x.start_station,
    end_station_id = x.end_station
FROM (
    SELECT
        s1.segment_id,
        st1.station_id AS start_station,
        st2.station_id AS end_station
    FROM Segment s1
    CROSS JOIN LATERAL (
        SELECT station_id
        FROM Station
        ORDER BY md5(random()::text || s1.segment_id::text)
        LIMIT 1
    ) st1
    CROSS JOIN LATERAL (
        SELECT station_id
        FROM Station
        WHERE station_id <> st1.station_id
        ORDER BY md5(random()::text || s1.segment_id::text || 'x')
        LIMIT 1
    ) st2
) x
WHERE s.segment_id = x.segment_id;


select * from segment limit 100;
select count(*) from segment;

-------------------------------------------------------
/*maintenance*/

INSERT INTO maintenance (maintenance_date, description, stationstation_id, segmentsegment_id)
SELECT * FROM (
    SELECT
        CURRENT_DATE - (floor(random() * 365) * INTERVAL '1 day') AS m_date,
        (ARRAY['Routine ', 'Emergency ', 'Scheduled ', 'Quarterly ', 'Post-incident '])[floor(random() * 5 + 1)] ||
        (ARRAY['inspection of ', 'repair of ', 'cleaning of ', 'structural check on ', 'electrical test for '])[floor(random() * 5 + 1)] ||
        (ARRAY['track alignment', 'signaling system', 'platform safety', 'ventilation', 'overhead cables'])[floor(random() * 5 + 1)] AS descr,
        s.station_id,
        seg.segment_id
    FROM segment seg
    JOIN station s ON s.station_id = seg.stationstation_id3
    CROSS JOIN LATERAL generate_series(1,
        CASE
            WHEN random() < 0.1 THEN 5
            WHEN random() < 0.6 THEN 12
            ELSE 20
        END
    ) g
) AS messy_data
ORDER BY random()
LIMIT 50000;

truncate table maintenance restart identity cascade ;

select count(*) from maintenance;
select * from maintenance limit 1000;


-------------------------------------------------------
/*plaform*/

WITH expanded AS (
    SELECT
        station_id,
        row_number() OVER (PARTITION BY station_id ORDER BY random()) AS p_id
    FROM station
    CROSS JOIN LATERAL generate_series(1, 5)
),
numbered AS (
    SELECT *,
           row_number() OVER (ORDER BY random()) AS global_rn
    FROM expanded
)
INSERT INTO platform (stationstation_id, platform_id, platform_number)
SELECT station_id, p_id, p_id
FROM numbered
WHERE global_rn <= 8000;

select * from platform limit 1000;
select count(*) from platform;

-------------------------------------------------------
/*schedule*/

INSERT INTO schedule (day_of_week, departure_time, arrival_time, status, routeroute_id, traintrain_id)
SELECT
    (floor(random() * 7) + 1)::text::bpchar(1),
    dep_date,
    dep_date + (floor(random() * 2))::int,
    (ARRAY['On Time', 'Delayed', 'Cancelled', 'Scheduled'])[floor(random() * 4 + 1)],
    routes.route_id,
    trains.train_id
FROM (
    SELECT
        CURRENT_DATE + (floor(random() * 30))::int AS dep_date,
        random() as r1,
        random() as r2
    FROM generate_series(1, 12000000)
) AS s
JOIN (
    SELECT route_id, row_number() OVER () as rn, count(*) OVER () as total
    FROM route
) AS routes ON routes.rn = floor(s.r1 * routes.total) + 1
JOIN (
    SELECT train_id, row_number() OVER () as rn, count(*) OVER () as total
    FROM train
) AS trains ON trains.rn = floor(s.r2 * trains.total) + 1;

select count(*) from schedule;
select * from schedule limit 1000;

-------------------------------------------------------
/*train trip*/
INSERT INTO "Train Trip" (
    departure_time,
    arrival_time,
    trip_status,
    delay_minutes,
    routeroute_id,
    traintrain_id,
    employeeemployee_id,
    employeepersonembg2,
    platformstationstation_id,
    platformplatform_id
)
SELECT
    s.dep_date,
    (s.dep_date + (CASE WHEN random() > 0.9 THEN interval '1 day' ELSE interval '0 days' END)),
    (ARRAY['Completed', 'Delayed', 'On Time', 'Cancelled', 'In Transit'])[floor(random() * 5 + 1)],
    (CASE WHEN random() > 0.85 THEN floor(random() * 181)::int ELSE 0 END),
    r.route_id,
    t.train_id,
    e.employee_id,
    e.personembg,
    p.stationstation_id,
    p.platform_id
FROM (
    SELECT
        (CURRENT_DATE - (floor(random() * 90) || ' days')::interval)::timestamp AS dep_date,
        random() as r1, random() as r2, random() as r3, random() as r4,
        generate_series(1, 500000)
) AS s
JOIN (SELECT route_id, row_number() OVER () as rn, count(*) OVER () as total FROM route) r
    ON r.rn = floor(s.r1 * r.total) + 1
JOIN (SELECT train_id, row_number() OVER () as rn, count(*) OVER () as total FROM train) t
    ON t.rn = floor(s.r2 * t.total) + 1
JOIN (SELECT employee_id, personembg, row_number() OVER () as rn, count(*) OVER () as total FROM employee) e
    ON e.rn = floor(s.r3 * e.total) + 1
JOIN (SELECT stationstation_id, platform_id, row_number() OVER () as rn, count(*) OVER () as total FROM platform) p
    ON p.rn = floor(s.r4 * p.total) + 1;

COMMIT;

select count(*) from "Train Trip";
select * from "Train Trip" limit 1000;

TRUNCATE TABLE "Train Trip" RESTART identity cascade;


select count(*) from train_undergoes_maintenance;
select * from train_undergoes_maintenance limit 1000;

-----Train Service---------------
WITH trip_rows AS (
    SELECT
        row_number() OVER (ORDER BY trip_id) AS rn,
        trip_id,
        departure_time,
        arrival_time,
        Traintrain_id
    FROM "Train Trip"
),
train_rows AS (
    SELECT
        row_number() OVER (ORDER BY train_id) AS rn,
        train_id,
        type
    FROM Train
),
trip_count AS (
    SELECT count(*) AS cnt FROM trip_rows
)
INSERT INTO "Train Service"
(service_id, service_type, opening_time, closing_time, "Train Triptrip_id", Traintrain_id)
SELECT
    gs AS service_id,
    trn.type AS service_type,

    CASE
        WHEN gs % 2 = 0 THEN make_date(2026, 4 + (gs % 9), 1 + (gs % 28))
        ELSE make_date(2027, 1 + (gs % 12), 1 + (gs % 28))
    END AS opening_time,

    CASE
        WHEN gs % 2 = 0 THEN make_date(2026, 4 + (gs % 9), 1 + (gs % 28)) + (gs % 3)
        ELSE make_date(2027, 1 + (gs % 12), 1 + (gs % 28)) + (gs % 3)
    END AS closing_time,

    t.trip_id AS "Train Triptrip_id",
    t.Traintrain_id AS Traintrain_id
FROM generate_series(1, 120000) AS gs
CROSS JOIN trip_count tc
JOIN trip_rows t
  ON t.rn = (((gs * 97) - 1) % tc.cnt) + 1
JOIN train_rows trn
  ON trn.train_id = t.Traintrain_id;

---------Employe_operates_Train Service-------------------
INSERT INTO "Employee_operates_Train Service"
(Employeeemployee_id, EmployeePersonEMBG2)
SELECT DISTINCT
    e.employee_id,
    e.PersonEMBG
FROM Employee e
WHERE e.position IN ('TrainDriver', 'AssistantDriver', 'Conductor', 'SignalOperator', 'StationMaster')
ORDER BY e.employee_id
LIMIT 90000
ON CONFLICT (Employeeemployee_id, EmployeePersonEMBG2) DO NOTHING;


---------Route_Segment----------------------
TRUNCATE TABLE Route_Segment;

INSERT INTO Route_Segment (
    Routeroute_id,
    Segmentsegment_id,
    sequence_number,
    stops_at_segment,
    is_station_stop,
    Stationstation_id,
    distance_from_start,
    estimated_time_offset
)
WITH base AS (
    SELECT DISTINCT
        r.route_id AS Routeroute_id,
        s.segment_id AS Segmentsegment_id,
        st.station_id AS Stationstation_id,
        CASE
            WHEN random() > 0.65 THEN 1
            ELSE 0
        END AS is_station_stop,
        random() AS rand_order
    FROM (
        SELECT
            random() AS r1,
            random() AS r2,
            random() AS r3
        FROM generate_series(1, 25000)
    ) g
    JOIN (
        SELECT
            route_id,
            row_number() OVER () AS rn,
            count(*) OVER () AS total
        FROM Route
    ) r
      ON r.rn = floor(g.r1 * r.total) + 1
    JOIN (
        SELECT
            segment_id,
            row_number() OVER () AS rn,
            count(*) OVER () AS total
        FROM Segment
    ) s
      ON s.rn = floor(g.r2 * s.total) + 1
    JOIN (
        SELECT
            station_id,
            row_number() OVER () AS rn,
            count(*) OVER () AS total
        FROM Station
    ) st
      ON st.rn = floor(g.r3 * st.total) + 1
),
numbered AS (
    SELECT
        Routeroute_id,
        Segmentsegment_id,
        is_station_stop,
        Stationstation_id,
        rand_order,
        row_number() OVER (
            PARTITION BY Routeroute_id
            ORDER BY rand_order
        ) AS sequence_number
    FROM base
),
final_rows AS (
    SELECT
        Routeroute_id,
        Segmentsegment_id,
        sequence_number,
        CASE
            WHEN is_station_stop = 1 THEN sequence_number
            ELSE NULL
        END AS stops_at_segment,
        is_station_stop,
        CASE
            WHEN is_station_stop = 1 THEN Stationstation_id
            ELSE NULL
        END AS Stationstation_id,
        (sequence_number * (5 + floor(random() * 16)::int))::float4 AS distance_from_start,
        (sequence_number * (4 + floor(random() * 12)::int))::int4 AS estimated_time_offset
    FROM numbered
)
SELECT
    Routeroute_id,
    Segmentsegment_id,
    sequence_number,
    stops_at_segment,
    is_station_stop,
    Stationstation_id,
    distance_from_start,
    estimated_time_offset
FROM final_rows
ORDER BY random()
LIMIT 15000
ON CONFLICT (Routeroute_id, Segmentsegment_id) DO NOTHING;

select count(*) from route_segment
select * from route_segment limit 1000;


----------Train_stops_at_station-------------------------

INSERT INTO train_stops_at_station
(
    Traintrain_id,
    Stationstation_id
)
WITH train_rows AS (
    SELECT
        t.train_id,
        3 + floor(random() * 3)::int AS stations_needed
    FROM Train t
),
picked AS (
    SELECT
        t.train_id,
        s.station_id
    FROM train_rows t
    CROSS JOIN LATERAL (
        SELECT station_id
        FROM Station
        ORDER BY random()
        LIMIT t.stations_needed
    ) s
)
SELECT
    train_id,
    station_id
FROM picked
ORDER BY random()
ON CONFLICT DO NOTHING;

select count(*) from train_stops_at_station
select * from train_stops_at_station limit 100;

---------Train Trip_Segment----------------------

TRUNCATE TABLE "Train Trip_Segment";

WITH trip_rows AS (
    SELECT
        tt.trip_id,
        row_number() OVER (ORDER BY tt.trip_id) AS trip_rn,
        CASE
            WHEN (row_number() OVER (ORDER BY tt.trip_id) % 10) < 5 THEN 2
            WHEN (row_number() OVER (ORDER BY tt.trip_id) % 10) < 8 THEN 3
            ELSE 4
        END AS segments_needed
    FROM "Train Trip" tt
),
segment_rows AS (
    SELECT
        sg.segment_id,
        row_number() OVER (ORDER BY sg.segment_id) AS seg_rn
    FROM Segment sg
),
seg_cnt AS (
    SELECT COUNT(*) AS cnt
    FROM segment_rows
),
picked AS (
    SELECT
        t.trip_id,
        gs.seq AS log_sequence_order,
        1 + ((t.trip_rn * 97 + gs.seq * 37) % c.cnt) AS seg_rn1,
        1 + ((t.trip_rn * 53 + gs.seq * 71) % c.cnt) AS seg_rn2
    FROM trip_rows t
    CROSS JOIN seg_cnt c
    CROSS JOIN LATERAL generate_series(1, t.segments_needed) AS gs(seq)
),
final_rows AS (
    SELECT DISTINCT ON (p.trip_id, s.segment_id)
        p.trip_id,
        s.segment_id,
        p.log_sequence_order,
        md5(p.trip_id::text || '-' || p.log_sequence_order::text) AS mix_key
    FROM picked p
    JOIN segment_rows s
      ON s.seg_rn = p.seg_rn1
      OR s.seg_rn = p.seg_rn2
)
INSERT INTO "Train Trip_Segment"
(
    "Train Triptrip_id",
    Segmentsegment_id,
    log_sequence_order
)
SELECT
    trip_id,
    segment_id,
    row_number() OVER (
        PARTITION BY trip_id
        ORDER BY mix_key
    ) AS log_sequence_order
FROM final_rows
ORDER BY md5(random()::text)
ON CONFLICT DO NOTHING;

-------Ticket ---------------
Truncate table ticket;
INSERT INTO Ticket
(
    seat_number,
    carriage_number,
    price,
    ticket_status,
    Paymentpayment_id,
    "Train Triptrip_id",
    Stationstation_id,
    Stationstation_id2
)
WITH payment_pool AS (
    SELECT
        p.payment_id,
        p.amount,
        p.transaction_date,
        row_number() OVER (ORDER BY p.payment_id) AS rn
    FROM Payment p
    WHERE p.transaction_date IS NOT NULL
      AND p.amount > 0
),
trip_pool AS (
    SELECT
        tt.trip_id,
        tr.type,
        row_number() OVER (ORDER BY tt.trip_id) AS rn
    FROM "Train Trip" tt
    JOIN Train tr
      ON tr.train_id = tt.Traintrain_id
),
station_pool AS (
    SELECT
        s.station_id,
        row_number() OVER (ORDER BY s.station_id) AS rn
    FROM Station s
),
counts AS (
    SELECT
        (SELECT COUNT(*) FROM payment_pool) AS payment_cnt,
        (SELECT COUNT(*) FROM trip_pool) AS trip_cnt,
        (SELECT COUNT(*) FROM station_pool) AS station_cnt
),
gen AS (
    SELECT generate_series(1, 12000000) AS g
),
picked AS (
    SELECT
        g.g,
        p.payment_id,
        p.amount,
        p.transaction_date,
        t.trip_id,
        t.type,
        s1.station_id AS start_station,
        s2.station_id AS end_station,
        random() AS r
    FROM gen g
    CROSS JOIN counts c
    JOIN payment_pool p
      ON p.rn = 1 + ((g.g - 1) % c.payment_cnt)
    JOIN trip_pool t
      ON t.rn = 1 + ((g.g * 13 - 1) % c.trip_cnt)
    JOIN station_pool s1
      ON s1.rn = 1 + ((g.g * 17 - 1) % c.station_cnt)
    JOIN station_pool s2
      ON s2.rn = 1 + ((g.g * 37 - 1) % c.station_cnt)
    WHERE s1.station_id <> s2.station_id
),
calc AS (
    SELECT
        g,
        payment_id,
        amount,
        trip_id,
        start_station,
        end_station,
        CASE
            WHEN type ILIKE 'fast' THEN LEAST(amount, (70 + floor(r * 20))::numeric)
            WHEN type ILIKE 'express' THEN LEAST(amount, (60 + floor(r * 20))::numeric)
            WHEN type ILIKE 'intercity' THEN LEAST(amount, (45 + floor(r * 20))::numeric)
            WHEN type ILIKE 'regional' THEN LEAST(amount, (25 + floor(r * 20))::numeric)
            ELSE LEAST(amount, (15 + floor(r * 30))::numeric)
        END::numeric(10,2) AS calc_price
    FROM picked
)
SELECT
    1 + ((g * 7) % 80) AS seat_number,
    1 + ((g * 3) % 10) AS carriage_number,
    calc_price AS price,
    'PAID' AS ticket_status,
    payment_id,
    trip_id,
    start_station,
    end_station
FROM calc;

--------------------------Updates--------------------------------------
UPDATE Segment s
SET
    start_station_id = x.start_station,
    end_station_id = x.end_station
FROM (
    SELECT
        s1.segment_id,
        st1.station_id AS start_station,
        st2.station_id AS end_station
    FROM Segment s1
    CROSS JOIN LATERAL (
        SELECT station_id
        FROM Station
        ORDER BY md5(random()::text || s1.segment_id::text)
        LIMIT 1
    ) st1
    CROSS JOIN LATERAL (
        SELECT station_id
        FROM Station
        WHERE station_id <> st1.station_id
        ORDER BY md5(random()::text || s1.segment_id::text || 'x')
        LIMIT 1
    ) st2
) x
WHERE s.segment_id = x.segment_id;

-----------------------------------------------------------

UPDATE "Train Trip" tt
SET
    start_station_id = x.start_station,
    end_station_id = x.end_station
FROM (
    SELECT
        trip_id,
        start_station,
        CASE
            WHEN start_station = end_station
                THEN ((end_station % total) + 1)
            ELSE end_station
        END AS end_station
    FROM (
        SELECT
            trip_id,
            1 + ((trip_id * 17) % total) AS start_station,
            1 + ((trip_id * 31) % total) AS end_station,
            total
        FROM "Train Trip"
        CROSS JOIN (
            SELECT COUNT(*) AS total
            FROM Station
        ) st
    ) q
) x
WHERE tt.trip_id = x.trip_id;
---------------------------------------------------------------


