---------------PROCEDURE-------------------------------------------------
CREATE OR REPLACE PROCEDURE pr_sell_ticket(
    IN p_passenger_embg CHAR(13),
    IN p_passenger_id INT4,
    IN p_trip_id INT4,
    IN p_start_station_id INT4,
    IN p_end_station_id INT4,
    IN p_seat_number INT4,
    IN p_carriage_number INT4,
    IN p_price NUMERIC(2, 0),
    IN p_payment_method VARCHAR(20),
    OUT o_ticket_id INT4,
    OUT o_payment_id INT4,
    IN p_reservation_id INT4 DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_passenger_exists INT;
    v_trip_exists INT;
    v_station_start_exists INT;
    v_station_end_exists INT;
    v_seat_taken INT;
BEGIN
    SELECT COUNT(*) INTO v_passenger_exists
    FROM Passenger
    WHERE PersonEMBG = p_passenger_embg AND passenger_id = p_passenger_id;

    IF v_passenger_exists = 0 THEN
        RAISE EXCEPTION 'Passenger with EMBG % and ID % does not exist.', p_passenger_embg, p_passenger_id;
    END IF;

    SELECT COUNT(*) INTO v_trip_exists FROM "Train Trip" WHERE trip_id = p_trip_id;
    IF v_trip_exists = 0 THEN
        RAISE EXCEPTION 'Train Trip ID % does not exist.', p_trip_id;
    END IF;

    SELECT COUNT(*) INTO v_station_start_exists FROM Station WHERE station_id = p_start_station_id;
    SELECT COUNT(*) INTO v_station_end_exists FROM Station WHERE station_id = p_end_station_id;
    IF v_station_start_exists = 0 OR v_station_end_exists = 0 THEN
        RAISE EXCEPTION 'Invalid origin or destination station provided.';
    END IF;

    SELECT COUNT(*) INTO v_seat_taken
    FROM Ticket
    WHERE "Train Triptrip_id" = p_trip_id
      AND carriage_number = p_carriage_number
      AND seat_number = p_seat_number
      AND ticket_status = 'Active';

    IF v_seat_taken > 0 THEN
        RAISE EXCEPTION 'Seat % in Carriage % is already booked for Trip %.', p_seat_number, p_carriage_number, p_trip_id;
    END IF;

    IF p_reservation_id IS NOT NULL THEN
        UPDATE Reservation
        SET status = 'Completed'
        WHERE reservation_id = p_reservation_id;
    END IF;

    INSERT INTO Payment (
        payment_method,
        amount,
        transaction_date,
        Reservationreservation_id,
        Passengerpassenger_id,
        PassengerPersonEMBG2
    )
    VALUES (
        p_payment_method,
        p_price,
        CURRENT_DATE,
        p_reservation_id,
        p_passenger_id,
        p_passenger_embg
    )
    RETURNING payment_id INTO o_payment_id;

    INSERT INTO Ticket (
        seat_number,
        carriage_number,
        price,
        ticket_status,
        Paymentpayment_id,
        "Train Triptrip_id",
        Stationstation_id,
        Stationstation_id2
    )
    VALUES (
        p_seat_number,
        p_carriage_number,
        p_price,
        'Active',
        o_payment_id,
        p_trip_id,
        p_start_station_id,
        p_end_station_id
    )
    RETURNING ticket_id INTO o_ticket_id;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Transaction rolled back due to error: %', SQLERRM;
        RAISE;
END;
$$;


DO $$
DECLARE
    v_ticket_output INT4;
    v_payment_output INT4;
BEGIN
    CALL pr_sell_ticket(
        p_passenger_embg   => '2510985918703',
        p_passenger_id     => 290,
        p_trip_id          => 4,
        p_start_station_id => 10,
        p_end_station_id   => 14,
        p_seat_number      => 22,
        p_carriage_number  => 2,
        p_price            => 45,
        p_payment_method   => 'Apple Pay',
        o_ticket_id        => v_ticket_output,
        o_payment_id       => v_payment_output,
        p_reservation_id   => NULL
    );

    RAISE NOTICE 'Sale Complete! Ticket ID: %, Payment ID: %', v_ticket_output, v_payment_output;
END $$;

select * from ticket where ticket_id='23989062';
-----------------------------------------------------------------------------------------
---------Procedura 1 ------------
CREATE OR REPLACE PROCEDURE apply_seasonal_discount(p_route_id INT, p_discount_pct NUMERIC)
AS $$
BEGIN
    UPDATE Ticket
    SET price = price * (1 - p_discount_pct / 100)
    WHERE "Train Triptrip_id" IN (
        SELECT trip_id FROM "Train Trip" WHERE Routeroute_id = p_route_id
    );

    RAISE NOTICE 'Fares for route % have been reduced by %%%.', p_route_id, p_discount_pct;
END;
$$ LANGUAGE plpgsql;


CALL apply_seasonal_discount(355, 20);

SELECT t.ticket_id, t.price, t.ticket_status, tt.trip_id, tt.Routeroute_id
FROM Ticket t
JOIN "Train Trip" tt ON t."Train Triptrip_id" = tt.trip_id
WHERE tt.Routeroute_id = 355;

select * from "Train Trip" where Routeroute_id=355;

---------Procedura 2 ------------

CREATE OR REPLACE PROCEDURE reassign_passengers_to_new_trip(p_cancelled_trip_id INT, p_new_trip_id INT)
AS $$
BEGIN
    UPDATE Ticket
    SET "Train Triptrip_id" = p_new_trip_id,
        ticket_status = 'Reassigned'
    WHERE "Train Triptrip_id" = p_cancelled_trip_id;

    UPDATE "Train Trip"
    SET trip_status = 'Cancelled'
    WHERE trip_id = p_cancelled_trip_id;

    RAISE NOTICE 'All passengers from % have been transferred to trip %.', p_cancelled_trip_id, p_new_trip_id;
END;
$$ LANGUAGE plpgsql;

SELECT ticket_id, "Train Triptrip_id", ticket_status
FROM Ticket
WHERE "Train Triptrip_id" = 380477;

SELECT ticket_id, "Train Triptrip_id", ticket_status
FROM Ticket
WHERE "Train Triptrip_id" = 200;

CALL reassign_passengers_to_new_trip(380477, 200);

-----Procedura 3 ------------------

CREATE OR REPLACE PROCEDURE change_trip_platform(
    p_trip_id INT,
    p_new_platform_id INT
)
AS $$
BEGIN
    UPDATE "Train Trip"
    SET Platformplatform_id = p_new_platform_id
    WHERE trip_id = p_trip_id;

    RAISE NOTICE 'Trip % has been transferred to platform %.', p_trip_id, p_new_platform_id;
END;
$$ LANGUAGE plpgsql;


CALL change_trip_platform(3300, 2);

select * from "Train Trip" where trip_id=3300

------Procedura 1------------

CREATE OR REPLACE PROCEDURE cancel_reservation(p_reservation_id INT)
AS $$
BEGIN
    UPDATE Reservation
    SET status = 'Cancelled'
    WHERE reservation_id = p_reservation_id;

    UPDATE Ticket
    SET ticket_status = 'Cancelled'
    WHERE Paymentpayment_id IN (
        SELECT payment_id
        FROM Payment
        WHERE Reservationreservation_id = p_reservation_id
    );
    RAISE NOTICE 'Reservation % has been canceled successfully.', p_reservation_id;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM Reservation where reservation_id = 17;

SELECT * FROM Ticket
WHERE Paymentpayment_id IN (
    SELECT payment_id FROM Payment WHERE Reservationreservation_id = 17
);

CALL cancel_reservation(17);

----------Procedura 2------------

CREATE OR REPLACE PROCEDURE update_trip_delay(p_trip_id INT, p_delay_mins INT)
AS $$
BEGIN
    UPDATE "Train Trip"
    SET delay_minutes = p_delay_mins,
        trip_status = CASE WHEN p_delay_mins > 0 THEN 'Delayed' ELSE 'On Time' END
    WHERE trip_id = p_trip_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Trip with ID % not found.', p_trip_id;
    END IF;
END;
$$ LANGUAGE plpgsql;

CALL update_trip_delay(1220, 15);

select * from "Train Trip" where trip_id=1220;


-------Procedura 3--------------

CREATE OR REPLACE PROCEDURE transfer_employee(
    p_embg CHAR(13),
    p_new_company_id INT
)
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Company WHERE company_id = p_new_company_id) THEN
        RAISE EXCEPTION 'Company ID % does not exist.', p_new_company_id;
    END IF;

    UPDATE Employee
    SET Companycompany_id = p_new_company_id
    WHERE PersonEMBG = p_embg;

    RAISE NOTICE 'Employee with EMBG % has been successfully transferred to company %.', p_embg, p_new_company_id;
END;
$$ LANGUAGE plpgsql;

CALL transfer_employee('2005992333958', 4);

select * from employee where PersonEMBG='2005992333958'


----------- Procedura 2 ----------------

CREATE OR REPLACE PROCEDURE assign_platform_to_trip(
    p_trip_id INT,
    p_platform_id INT,
    p_station_id INT
)
AS $$
BEGIN
    UPDATE "Train Trip"
    SET Platformplatform_id = p_platform_id,
        PlatformStationstation_id = p_station_id
    WHERE trip_id = p_trip_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Trip with ID % not found.', p_trip_id;
    END IF;

    RAISE NOTICE 'Platform % assigned to trip %.',
                 p_platform_id, p_trip_id;
END;
$$ LANGUAGE plpgsql;
CALL assign_platform_to_trip(3300, 3, 1084);