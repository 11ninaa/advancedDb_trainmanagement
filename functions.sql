-------------------------------FUNKCIJA 1 ---------------------------
CREATE OR REPLACE FUNCTION free_seats_trip(
    p_trip_id INT
)
RETURNS INT
AS $$
DECLARE
    v_capacity INT;
    v_sold_tickets INT;
BEGIN
    SELECT t.capacity
    INTO v_capacity
    FROM "Train Trip" tt
    JOIN Train t
        ON tt.Traintrain_id = t.train_id
    WHERE tt.trip_id = p_trip_id;

    SELECT COUNT(*)
    INTO v_sold_tickets
    FROM Ticket
    WHERE "Train Triptrip_id" = p_trip_id;

    RETURN v_capacity - v_sold_tickets;
END;
$$ LANGUAGE plpgsql;

SELECT free_seats_trip(155);

---------FUNKCIJA 1-----------

CREATE OR REPLACE FUNCTION get_available_seats(p_trip_id INT)
RETURNS INT AS $$
DECLARE
    v_capacity INT;
    v_sold_tickets INT;
BEGIN
    SELECT t.capacity INTO v_capacity
    FROM "Train Trip" tt
    JOIN Train t ON tt.Traintrain_id = t.train_id
    WHERE tt.trip_id = p_trip_id;

    SELECT COUNT(*) INTO v_sold_tickets
    FROM Ticket
    WHERE "Train Triptrip_id" = p_trip_id;

    RETURN v_capacity - v_sold_tickets;
END;
$$ LANGUAGE plpgsql;

SELECT get_available_seats(345895);
SELECT get_available_seats(155);


----------FUNKCIJA 2----------------

CREATE OR REPLACE FUNCTION get_trip_revenue_efficiency(p_trip_id INT)
RETURNS TEXT AS $$
DECLARE
    v_capacity INT;
    v_sold_count INT;
    v_total_revenue NUMERIC;
    v_occupancy_pct NUMERIC;
    v_rev_per_seat NUMERIC;
    v_result TEXT;
BEGIN
    SELECT t.capacity INTO v_capacity
    FROM "Train Trip" tt
    JOIN Train t ON tt.Traintrain_id = t.train_id
    WHERE tt.trip_id = p_trip_id;

    SELECT COUNT(*), COALESCE(SUM(price), 0)
    INTO v_sold_count, v_total_revenue
    FROM Ticket
    WHERE "Train Triptrip_id" = p_trip_id;

    IF v_capacity > 0 THEN
        v_occupancy_pct := (v_sold_count::NUMERIC / v_capacity) * 100;
        v_rev_per_seat := v_total_revenue / v_capacity;
    ELSE
        RETURN 'Error: Train has no capacity';
    END IF;

    IF v_occupancy_pct >= 85 THEN
        v_result := 'High Demand (' || ROUND(v_occupancy_pct, 1) || '%)';
    ELSIF v_occupancy_pct >= 50 THEN
        v_result := 'Optimal (' || ROUND(v_occupancy_pct, 1) || '%)';
    ELSE
        v_result := 'Low Efficiency (' || ROUND(v_occupancy_pct, 1) || '%)';
    END IF;

    RETURN v_result || ' | Rev/Seat: ' || ROUND(v_rev_per_seat, 2);
END;
$$ LANGUAGE plpgsql;

SELECT
    tt.trip_id,
    r.route_name,
    tt.departure_time,
    get_trip_revenue_efficiency(tt.trip_id) AS performance_report
FROM "Train Trip" tt
JOIN Route r ON tt.Routeroute_id = r.route_id
WHERE tt.trip_status = 'Completed'
ORDER BY tt.departure_time DESC
LIMIT 150;


-------FUNKCIJA 3--------------

CREATE OR REPLACE FUNCTION get_passenger_name_by_id(p_id INT)
RETURNS VARCHAR AS $$
DECLARE
    v_full_name VARCHAR;
BEGIN
    SELECT p.first_name || ' ' || p.last_name INTO v_full_name
    FROM Passenger pass
    JOIN Person p ON pass.PersonEMBG = p.EMBG
    WHERE pass.passenger_id = p_id;

    RETURN COALESCE(v_full_name, 'Passenger not found');
END;
$$ LANGUAGE plpgsql;

SELECT get_passenger_name_by_id(500);

----------- FUNKCIJA 4----------------

CREATE OR REPLACE FUNCTION get_most_profitable_route()
RETURNS TEXT AS $$
DECLARE
    v_route_name VARCHAR;
    v_total_revenue NUMERIC;
BEGIN
    SELECT
        r.route_name,
        COALESCE(SUM(t.price), 0)
    INTO
        v_route_name,
        v_total_revenue
    FROM Route r
    JOIN "Train Trip" tt
        ON r.route_id = tt.Routeroute_id
    JOIN Ticket t
        ON tt.trip_id = t."Train Triptrip_id"
    GROUP BY r.route_id, r.route_name
    ORDER BY SUM(t.price) DESC
    LIMIT 1;

    RETURN
        'Most Profitable Route: ' || v_route_name ||
        ' | Total Revenue: ' || ROUND(v_total_revenue, 2);
END;
$$ LANGUAGE plpgsql;

SELECT get_most_profitable_route();

----------- FUNKCIJA 5----------------

CREATE OR REPLACE FUNCTION check_frequent_traveler(p_passenger_id INT)
RETURNS TEXT AS $$
DECLARE
    v_ticket_count INT;
    v_full_name VARCHAR;
BEGIN

    SELECT p.first_name || ' ' || p.last_name
    INTO v_full_name
    FROM Passenger pass
    JOIN Person p ON pass.PersonEMBG = p.EMBG
    WHERE pass.passenger_id = p_passenger_id
    LIMIT 1;

    SELECT COUNT(t.ticket_id)
    INTO v_ticket_count
    FROM Ticket t
    JOIN Payment pay ON t.Paymentpayment_id = pay.payment_id
    JOIN Reservation r ON pay.Reservationreservation_id = r.reservation_id
    WHERE r.Passengerpassenger_id = p_passenger_id;

    IF v_ticket_count >= 20 THEN
        RETURN v_full_name || ' is a VIP Frequent Traveler with ' || v_ticket_count || ' trips.';
    ELSIF v_ticket_count >= 10 THEN
        RETURN v_full_name || ' is a Frequent Traveler with ' || v_ticket_count || ' trips.';
    ELSIF v_ticket_count > 0 THEN
        RETURN v_full_name || ' is an Occasional Traveler with ' || v_ticket_count || ' trips.';
    ELSE
        RETURN v_full_name || ' has no trips.';
    END IF;
END;
$$ LANGUAGE plpgsql;

SELECT check_frequent_traveler(800);

----------- FUNKCIJA 6 ----------------

CREATE OR REPLACE FUNCTION get_revenue_by_period(
    p_start_date DATE,
    p_end_date DATE
)
RETURNS TEXT AS $$
DECLARE
    v_total_tickets INT;
    v_total_revenue NUMERIC;
BEGIN
    SELECT
        COUNT(*),
        COALESCE(SUM(t.price), 0)
    INTO
        v_total_tickets,
        v_total_revenue
    FROM Ticket t
    JOIN "Train Trip" tt
        ON t."Train Triptrip_id" = tt.trip_id
    WHERE tt.departure_time::DATE
          BETWEEN p_start_date AND p_end_date;

    RETURN
        'Period: ' || p_start_date || ' to ' || p_end_date ||
        ' | Tickets Sold: ' || v_total_tickets ||
        ' | Total Revenue: ' || ROUND(v_total_revenue, 2);
END;
$$ LANGUAGE plpgsql;

SELECT get_revenue_by_period('2025-01-01', '2026-03-31');

----------- FUNKCIJA 7 ----------------

CREATE FUNCTION get_passenger_total_spending(
    p_embg CHAR(13)
)
RETURNS NUMERIC AS $$
DECLARE
    total_spending NUMERIC;
BEGIN

    SELECT COALESCE(SUM(pay.amount), 0)
    INTO total_spending
    FROM Payment pay
    JOIN Passenger pas
      ON pas.PersonEMBG = pay.PassengerPersonEMBG2
    WHERE pas.PersonEMBG = p_embg;

    RETURN total_spending;

END;
$$ LANGUAGE plpgsql;

SELECT get_passenger_total_spending('2509982211077');

----------- FUNKCIJA 8 ----------------

CREATE FUNCTION get_next_departing_trains()
RETURNS TABLE (
    trip_id INT,
    train_id INT,
    departure_time DATE,
    arrival_time DATE,
    trip_status VARCHAR
)
AS $$
BEGIN

    RETURN QUERY
    SELECT
        tt.trip_id,
        tt.Traintrain_id,
        tt.departure_time,
        tt.arrival_time,
        tt.trip_status
    FROM "Train Trip" tt
    WHERE tt.departure_time >= CURRENT_DATE
    ORDER BY tt.departure_time ASC;

END;
$$ LANGUAGE plpgsql;

SELECT * FROM get_next_departing_trains();

----------- FUNKCIJA 9 ----------------

CREATE FUNCTION get_route_stations(
    p_route_id INT
)
RETURNS TABLE (
    sequence_number INT,
    station_name VARCHAR,
    city VARCHAR
)
AS $$
BEGIN

    RETURN QUERY
    SELECT
        rs.sequence_number,
        st.station_name,
        st.city
    FROM Route_Segment rs
    JOIN Station st
      ON st.station_id = rs.Stationstation_id
    WHERE rs.Routeroute_id = p_route_id
    ORDER BY rs.sequence_number;

END;
$$ LANGUAGE plpgsql;

SELECT * FROM get_route_stations(1);
