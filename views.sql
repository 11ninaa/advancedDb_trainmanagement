---------FunctionalView ConductorList---------------
-- Shows passengers with seat number, carriage number, and boarding and alighting stations for a given train.
-- Used by conductors to check tickets.

CREATE VIEW view_conductor_list AS
SELECT
    tt.trip_id,
    t.train_number,
    tk.ticket_id,
    tk.seat_number,
    tk.carriage_number,
    p.first_name || ' ' || p.last_name AS passenger,
    s1.station_name AS departure_station,
    s2.station_name AS arrival_station,
    tt.departure_time
FROM Ticket tk
JOIN "Train Trip" tt ON tk."Train Triptrip_id" = tt.trip_id
JOIN Train t ON tt.Traintrain_id = t.train_id
JOIN Payment pay ON tk.Paymentpayment_id = pay.payment_id
JOIN Passenger pass ON pay.Passengerpassenger_id = pass.passenger_id
     AND pay.PassengerPersonEMBG2 = pass.PersonEMBG
JOIN Person p ON pass.PersonEMBG = p.EMBG
JOIN Station s1 ON tk.Stationstation_id = s1.station_id
JOIN Station s2 ON tk.Stationstation_id2 = s2.station_id;

select * from view_conductor_list where trip_id=345895;


---------FunctionalView UserHistory---------------
-- Shows a passenger's ticket history, including whether the trip is past or upcoming.

CREATE VIEW view_user_ticket_history AS
SELECT
    pass.passenger_id,
    p.first_name || ' ' || p.last_name AS passenger_name,
    tk.ticket_id,
    tt.departure_time,
    r.route_name,
    tk.ticket_status,
    CASE
        WHEN tt.departure_time >= CURRENT_DATE THEN 'Upcoming'
        ELSE 'Past'
    END AS travel_period
FROM Ticket tk
JOIN "Train Trip" tt ON tk."Train Triptrip_id" = tt.trip_id
JOIN Route r ON tt.Routeroute_id = r.route_id
JOIN Payment pay ON tk.Paymentpayment_id = pay.payment_id
JOIN Passenger pass ON pay.Passengerpassenger_id = pass.passenger_id
JOIN Person p ON pass.PersonEMBG = p.EMBG;


select * from view_user_ticket_history where passenger_id=689371;


-------FunctionalView StationDepartures------------
-- Shows all upcoming departures from a station, sorted by departure time, with status and delay.

CREATE VIEW view_station_departures AS
SELECT s.station_id, s.station_name,tt.trip_id,r.route_name, tt.departure_time, tt.trip_status, tt.delay_minutes
FROM "Train Trip" tt
JOIN Route r ON tt.Routeroute_id = r.route_id
JOIN Platform pl ON tt.PlatformStationstation_id = pl.Stationstation_id AND tt.Platformplatform_id = pl.platform_id
JOIN Station s ON pl.Stationstation_id = s.station_id
WHERE tt.departure_time >= CURRENT_DATE
ORDER BY tt.departure_time ASC;

select * from view_station_departures where trip_id=47138;


-------FunctionalView StationArrivals------------
-- Shows all upcoming arrivals at a station, sorted by arrival time, with status and delay.

CREATE VIEW view_station_arrivals AS
SELECT s.station_id, s.station_name, tt.trip_id,r.route_name, tt.arrival_time, tt.trip_status, tt.delay_minutes
FROM "Train Trip" tt
JOIN Route r ON tt.Routeroute_id = r.route_id
JOIN Platform pl ON tt.PlatformStationstation_id = pl.Stationstation_id AND tt.Platformplatform_id = pl.platform_id
JOIN Station s ON pl.Stationstation_id = s.station_id
WHERE tt.arrival_time >= CURRENT_DATE
ORDER BY tt.arrival_time ASC;

select * from view_station_arrivals where trip_id=146474;


-------FunctionalView FreeSeatsPerTrip------------
-- Shows free and occupied seats for each trip, based on train capacity and tickets sold.

CREATE OR REPLACE VIEW vw_free_seats_per_trip AS
SELECT
    tt.trip_id,
    COALESCE(t.capacity, 0) AS total_capacity,
    COUNT(tk.ticket_id) AS sold_tickets, 
    (COALESCE(t.capacity, 0) - COUNT(tk.ticket_id)) AS free_seats
FROM "Train Trip" tt
JOIN Train t
    ON tt.Traintrain_id = t.train_id
LEFT JOIN Ticket tk
    ON tt.trip_id = tk."Train Triptrip_id"
GROUP BY tt.trip_id, t.capacity;

SELECT * FROM vw_free_seats_per_trip;

SELECT free_seats FROM vw_free_seats_per_trip WHERE trip_id = 155;

-------FunctionalView ActiveDelays----------------
-- Shows active trips that are currently delayed, with the current station and delay in minutes.

CREATE OR REPLACE VIEW active_delays AS
SELECT
    tt.trip_id,
    r.route_name,
    t.train_number,
    tt.departure_time,
    tt.delay_minutes,
    s.station_name AS current_stop
FROM "train_trip_old" tt
JOIN Route r ON tt.Routeroute_id = r.route_id
JOIN Train t ON tt.Traintrain_id = t.train_id
JOIN Station s ON tt.PlatformStationstation_id = s.station_id
WHERE tt.delay_minutes > 0 AND tt.trip_status NOT IN('Completed', 'Cancelled') AND tt.departure_time <= CURRENT_TIMESTAMP
AND tt.arrival_time >= CURRENT_TIMESTAMP;

select * from active_delays;
select count(*) from active_delays;


------AnalyticalView Route_Infrastructure_Stats
-- Shows infrastructure statistics per route: total length, number of segments, and average and minimum allowed speed.


CREATE VIEW view_route_infrastructure_stats AS
SELECT
    r.route_name,
    COUNT(rs.Segmentsegment_id) AS total_segments,
    SUM(seg.length_km) AS total_route_length_km,
    MIN(seg.max_speed) AS bottleneck_speed,
    AVG(seg.max_speed) AS average_speed_limit
FROM Route r
JOIN Route_Segment rs ON r.route_id = rs.Routeroute_id
JOIN Segment seg ON rs.Segmentsegment_id = seg.segment_id
GROUP BY r.route_id, r.route_name;

SELECT
    route_name,
    total_segments,
    total_route_length_km
FROM view_route_infrastructure_stats
ORDER BY total_route_length_km DESC
LIMIT 10;

select * from view_route_infrastructure_stats where route_name='Venice - Bari';


---------AnalyticalView RoutePassengerSummary--------------
-- Shows the total number of tickets sold and the revenue per route.

CREATE VIEW view_route_passenger_summary AS
SELECT
    r.route_id,
    r.route_name,
    COUNT(tk.ticket_id) AS total_tickets_sold,
    SUM(tk.price) AS total_revenue
FROM Route r
LEFT JOIN "Train Trip" tt ON r.route_id = tt.Routeroute_id
LEFT JOIN Ticket tk ON tt.trip_id = tk."Train Triptrip_id"
GROUP BY r.route_id, r.route_name;

SELECT * FROM view_route_passenger_summary WHERE route_id = 517;

DROP VIEW IF EXISTS view_route_passenger_summary;

CREATE MATERIALIZED VIEW view_route_passenger_summary AS
SELECT
    r.route_id,
    r.route_name,
    COUNT(tk.ticket_id) AS total_tickets_sold,
    SUM(tk.price) AS total_revenue
FROM Route r
LEFT JOIN "Train Trip" tt ON r.route_id = tt.Routeroute_id
LEFT JOIN Ticket tk ON tt.trip_id = tk."Train Triptrip_id"
GROUP BY r.route_id, r.route_name;

SELECT * FROM view_route_passenger_summary WHERE route_id = 517;

--------AnalyticalView RouteTripStats
-- Shows the total number of trips and the average delay per route.


CREATE VIEW route_trip_stats AS
SELECT
    r.route_id,
    r.route_name,
    COUNT(tt.trip_id) AS total_trips,
    AVG(tt.delay_minutes) AS avg_delay
FROM Route r
LEFT JOIN "Train Trip" tt ON tt.Routeroute_id = r.route_id
GROUP BY r.route_id, r.route_name;

select * from route_trip_stats where route_id=489;


--------AnalyticalView TrainUtilization----------
-- Shows the total number of trips and the average delay per train, for utilization and punctuality.

CREATE VIEW view_train_utilization AS
SELECT
    t.train_id,
    t.train_number,
    COUNT(tt.trip_id) AS total_trips,
    AVG(tt.delay_minutes) AS avg_delay_minutes
FROM Train t
LEFT JOIN "Train Trip" tt ON t.train_id = tt.Traintrain_id
GROUP BY t.train_id, t.train_number;

SELECT * FROM view_train_utilization WHERE train_id = 91;

---------AnalyticalView TrainMaintenanceStats ------------
-- Shows the total number of services and assigned technicians per train, for maintenance history.

CREATE VIEW train_maintenance_stats AS
SELECT
    t.train_id,
    t.train_number,
    COUNT(DISTINCT tum.maintenancemaintenance_id) AS total_services,
    COUNT(DISTINCT epm.employeeemployee_id) AS total_technicians_involved
FROM Train t
LEFT JOIN train_undergoes_maintenance tum ON t.train_id = tum.traintrain_id
LEFT JOIN employee_performs_maintenance epm ON tum.maintenancemaintenance_id = epm.maintenancemaintenance_id
GROUP BY t.train_id, t.train_number;

select * from train_maintenance_stats where train_id=940;

------------AnalyticalView StationTrafficAndRevenue----------
-- Shows the total number of passengers, revenue, and distinct trains per station.

CREATE VIEW station_traffic_and_revenue AS
SELECT
    s.station_id,
    s.station_name,
    s.city,
    COUNT(tk.ticket_id) AS passengers_departed,
    SUM(tk.price) AS revenue_generated,
    COUNT(DISTINCT tt.Traintrain_id) AS unique_trains_passed
FROM Station s
JOIN Ticket tk ON s.station_id = tk.Stationstation_id
JOIN "Train Trip" tt ON tk."Train Triptrip_id" = tt.trip_id
GROUP BY s.station_id, s.station_name, s.city;

select * from station_traffic_and_revenue where station_id=14;

DROP VIEW IF EXISTS station_traffic_and_revenue;

CREATE MATERIALIZED VIEW station_traffic_and_revenue AS
SELECT
    s.station_id,
    s.station_name,
    s.city,
    COUNT(tk.ticket_id) AS passengers_departed,
    SUM(tk.price) AS revenue_generated,
    COUNT(DISTINCT tt.Traintrain_id) AS unique_trains_passed
FROM Station s
JOIN Ticket tk ON s.station_id = tk.Stationstation_id
JOIN "Train Trip" tt ON tk."Train Triptrip_id" = tt.trip_id
GROUP BY s.station_id, s.station_name, s.city;

select * from station_traffic_and_revenue where station_id=14;


