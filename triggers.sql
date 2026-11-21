------------------------------------------------------------------
-- auto_set_reservation_status
CREATE FUNCTION auto_set_reservation_status()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.expiry_time < CURRENT_DATE THEN
        NEW.status := 'Expired';
    ELSE
        NEW.status := 'Active';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_auto_set_reservation_status
BEFORE INSERT OR UPDATE ON Reservation
FOR EACH ROW
EXECUTE FUNCTION auto_set_reservation_status();

-------------------------------------------------------------
--prevent_duplicate_seat_booking
CREATE  FUNCTION prevent_duplicate_seat_booking()
RETURNS TRIGGER AS $$
DECLARE
    seat_exists INT;
BEGIN
    SELECT COUNT(*)
    INTO seat_exists
    FROM Ticket
    WHERE seat_number = NEW.seat_number
      AND carriage_number = NEW.carriage_number
      AND "Train Triptrip_id" = NEW."Train Triptrip_id";

    IF seat_exists > 0 THEN
        RAISE EXCEPTION 'Seat already booked for this train trip!';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_prevent_duplicate_seat_booking
BEFORE INSERT ON Ticket
FOR EACH ROW
EXECUTE FUNCTION prevent_duplicate_seat_booking();

----------------------------------------------------------------------
--update_trip_status_based_on_delay
CREATE FUNCTION update_trip_status_based_on_delay()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.delay_minutes > 0 THEN
        NEW.trip_status := 'Delayed';
    ELSE
        NEW.trip_status := 'On Time';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_trip_status
BEFORE INSERT OR UPDATE ON "Train Trip"
FOR EACH ROW
EXECUTE FUNCTION update_trip_status_based_on_delay();

----------------------------------------------------------------------------
--auto_set_transaction_date
CREATE FUNCTION auto_set_transaction_date()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.transaction_date IS NULL THEN
        NEW.transaction_date := CURRENT_DATE;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_auto_set_transaction_date
BEFORE INSERT ON Payment
FOR EACH ROW
EXECUTE FUNCTION auto_set_transaction_date();

----------------------------------------------------------------------------------
-- prevent_employee_trip_overlap
CREATE FUNCTION prevent_employee_trip_overlap()
RETURNS TRIGGER AS $$
DECLARE
    overlap_count INT;
BEGIN
    SELECT COUNT(*)
    INTO overlap_count
    FROM "Train Trip"
    WHERE Employeeemployee_id = NEW.Employeeemployee_id
      AND EmployeePersonEMBG2 = NEW.EmployeePersonEMBG2
      AND departure_time = NEW.departure_time;

    IF overlap_count > 0 THEN
        RAISE EXCEPTION
        'Employee already assigned to another trip at this time!';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_prevent_employee_trip_overlap
BEFORE INSERT ON "Train Trip"
FOR EACH ROW
EXECUTE FUNCTION prevent_employee_trip_overlap();

------------------------------------------------------------------------------
-- prevent_station_delete_active_trip
CREATE FUNCTION prevent_station_delete_active_trip()
RETURNS TRIGGER AS $$
DECLARE
    trip_count INT;
BEGIN
    SELECT COUNT(*)
    INTO trip_count
    FROM Ticket
    WHERE Stationstation_id = OLD.station_id
       OR Stationstation_id2 = OLD.station_id;

    IF trip_count > 0 THEN
        RAISE EXCEPTION
        'Cannot delete station because tickets/trips reference it!';
    END IF;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_prevent_station_delete_active_trip
BEFORE DELETE ON Station
FOR EACH ROW
EXECUTE FUNCTION prevent_station_delete_active_trip();

---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION check_and_mark_overbooked()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_capacity INT;
    v_sold_tickets INT;
BEGIN
    SELECT t.capacity
    INTO v_capacity
    FROM "Train Trip" tt
    JOIN Train t ON tt.Traintrain_id = t.train_id
    WHERE tt.trip_id = NEW."Train Triptrip_id";

    SELECT COUNT(*)
    INTO v_sold_tickets
    FROM Ticket
    WHERE "Train Triptrip_id" = NEW."Train Triptrip_id"
      AND ticket_status = 'Active';

    IF v_sold_tickets > v_capacity THEN
        UPDATE "Train Trip"
        SET trip_status = 'Overbooked'
        WHERE trip_id = NEW."Train Triptrip_id";

        RAISE NOTICE 'Trip % is OVERBOOKED automatically via Trigger. Capacity: %, Sold: %.',
                     NEW."Train Triptrip_id", v_capacity, v_sold_tickets;
    END IF;

    RETURN NEW;
END;
$$;