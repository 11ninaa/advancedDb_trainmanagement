CREATE TABLE Company (
  company_id SERIAL,
  name VARCHAR(100) NOT NULL UNIQUE,
  contact_info VARCHAR(255) NOT NULL,
  PRIMARY KEY (company_id),
  CONSTRAINT check_name_length CHECK (char_length(trim(name)) >= 2)
);
CREATE TABLE Person (
    EMBG CHAR(13) NOT NULL DEFAULT '0000000000000',
  first_name VARCHAR(20) NOT NULL DEFAULT 'Unknown',
  last_name VARCHAR(20) NOT NULL DEFAULT 'Unknown',
  gender CHAR(1) NOT NULL DEFAULT 'O',
  nationality VARCHAR(20) NOT NULL DEFAULT 'Unknown',
  phone_number VARCHAR(20) NOT NULL DEFAULT '+00000000000',
  email VARCHAR(40) NOT NULL DEFAULT 'example@email.com',
  PRIMARY KEY (EMBG),
    CONSTRAINT check_email_format
    CHECK (email ~* '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$'),
  CONSTRAINT check_phone_format
    CHECK (phone_number ~ '^\+?[0-9]{7,15}$'),
  CONSTRAINT check_gender
    CHECK (gender IN ('M', 'F', 'O'))
);

CREATE TABLE Employee (
  PersonEMBG CHAR(13) NOT NULL,
  employee_id SERIAL,
  position VARCHAR(20) NOT NULL,
  Companycompany_id int4 NOT NULL,
  PRIMARY KEY (PersonEMBG, employee_id),
  CONSTRAINT check_embg_numeric CHECK (PersonEMBG ~ '^[0-9]{13}$'),
  CONSTRAINT check_employee_id_positive CHECK (employee_id > 0),
  CONSTRAINT chk_position
  CHECK (position IN ('TrainDriver','AssistantDriver','Conductor','SignalOperator','MaintenanceWorker','StationMaster','Chef','Waiter','Cashier')),
    CONSTRAINT generalization FOREIGN KEY (PersonEMBG) REFERENCES Person (EMBG) ON DELETE RESTRICT,
    CONSTRAINT has FOREIGN KEY (Companycompany_id) REFERENCES Company (company_id) ON DELETE RESTRICT
);

CREATE TABLE "Employee_operates_Train Service" (
  Employeeemployee_id int4 NOT NULL,
  EmployeePersonEMBG2 CHAR(13) NOT NULL,
  PRIMARY KEY (Employeeemployee_id, EmployeePersonEMBG2),
    CONSTRAINT FKEmployee_o94327 FOREIGN KEY (EmployeePersonEMBG2, Employeeemployee_id) REFERENCES Employee (PersonEMBG, employee_id)
);

CREATE TABLE Segment (
  segment_id SERIAL NOT NULL,
  length_km NUMERIC(2, 0),
  type VARCHAR(20),
  max_speed int4,
  status VARCHAR(20),
  Stationstation_id3 int4 NOT NULL,
  PRIMARY KEY (segment_id)
);

CREATE TABLE Station (
  station_id SERIAL NOT NULL,
  station_name VARCHAR(20),
  country VARCHAR(40),
  city VARCHAR(20),
  address VARCHAR(40),
  PRIMARY KEY (station_id)
);


CREATE TABLE Maintenance (
  maintenance_id SERIAL,
  maintenance_date date NOT NULL,
  description VARCHAR(1000) NOT NULL,
  Stationstation_id int4 NOT NULL,
  Segmentsegment_id int4 NOT NULL,
  PRIMARY KEY (maintenance_id),
  CONSTRAINT check_maintenance_date CHECK (maintenance_date > '2000-01-01'),
    CONSTRAINT at FOREIGN KEY (Stationstation_id) REFERENCES Station (station_id),
     CONSTRAINT undergoes FOREIGN KEY (Segmentsegment_id) REFERENCES Segment (segment_id)
);
CREATE TABLE Employee_performs_Maintenance (
  Employeeemployee_id int4 NOT NULL,
  Maintenancemaintenance_id int4 NOT NULL,
  EmployeePersonEMBG2 CHAR(13) NOT NULL,
  PRIMARY KEY (
    Employeeemployee_id,
    Maintenancemaintenance_id,
    EmployeePersonEMBG2
  ),
    CONSTRAINT FKEmployee_p144416 FOREIGN KEY (Maintenancemaintenance_id) REFERENCES Maintenance (maintenance_id),
    CONSTRAINT FKEmployee_p884220 FOREIGN KEY (EmployeePersonEMBG2, Employeeemployee_id) REFERENCES Employee (PersonEMBG, employee_id)

);


CREATE TABLE Passenger (
  PersonEMBG CHAR(13) NOT NULL,
  passenger_id int4 NOT NULL,
  PRIMARY KEY (PersonEMBG, passenger_id),
  CONSTRAINT check_passenger_embg_format CHECK (PersonEMBG ~ '^[0-9]{13}$'),
  CONSTRAINT check_passenger_id_positive CHECK (passenger_id > 0),
    CONSTRAINT "generalization " FOREIGN KEY (PersonEMBG) REFERENCES Person (EMBG) ON DELETE RESTRICT
);
CREATE TABLE Reservation (
  reservation_id SERIAL NOT NULL,
  status VARCHAR(20),
  expiry_time date,
  Passengerpassenger_id int4 NOT NULL,
  PassengerPersonEMBG2 CHAR(13) NOT NULL,
  PRIMARY KEY (reservation_id),
    CONSTRAINT pass_makes FOREIGN KEY (PassengerPersonEMBG2, Passengerpassenger_id) REFERENCES Passenger (PersonEMBG, passenger_id)
);

CREATE TABLE Payment (
  payment_id SERIAL,
  payment_method VARCHAR(20) ,
  amount NUMERIC(2, 0),
  transaction_date date,
  Reservationreservation_id int4 NOT NULL,
  Passengerpassenger_id int4 NOT NULL,
  PassengerPersonEMBG2 CHAR(13) NOT NULL,
  PRIMARY KEY (payment_id),
    CONSTRAINT makes FOREIGN KEY (PassengerPersonEMBG2, Passengerpassenger_id) REFERENCES Passenger (PersonEMBG, passenger_id),
CONSTRAINT paid_by FOREIGN KEY (Reservationreservation_id) REFERENCES Reservation (reservation_id) ON DELETE CASCADE
    -- A payment record is tied to a specific reservation; if the reservation is purged, the payment link goes too.
);



CREATE TABLE Platform (
  Stationstation_id int4 NOT NULL,
  platform_id int4 NOT NULL,
  platform_number int4,
  PRIMARY KEY (Stationstation_id, platform_id),
    CONSTRAINT station_has FOREIGN KEY (Stationstation_id) REFERENCES Station (station_id) ON DELETE RESTRICT
);



CREATE TABLE Route (
  route_id SERIAL NOT NULL,
  route_name VARCHAR(20),
  type int4,
  PRIMARY KEY (route_id)
);

CREATE TABLE Route_Segment (
  Routeroute_id int4 NOT NULL,
  Segmentsegment_id int4 NOT NULL,
  sequence_number int4 NOT NULL,
  stops_at_segment int4 DEFAULT NULL,
  is_station_stop int2 DEFAULT 0,
  Stationstation_id int4,
  distance_from_start float4,
  estimated_time_offset int4,
  PRIMARY KEY (Routeroute_id, Segmentsegment_id),
CONSTRAINT FKRoute_Segm456953 FOREIGN KEY (Stationstation_id) REFERENCES Station (station_id),
    CONSTRAINT FKRoute_Segm742581 FOREIGN KEY (Segmentsegment_id) REFERENCES Segment (segment_id),
    CONSTRAINT FKRoute_Segm866494 FOREIGN KEY (Routeroute_id) REFERENCES Route (route_id) ON DELETE CASCADE ,
    -- If a Route is deleted, all its segment mappings are automatically removed.
    CONSTRAINT is_located_on FOREIGN KEY (Stationstation_id) REFERENCES Station (station_id) ON DELETE RESTRICT

);


CREATE TABLE Train (
  train_id SERIAL NOT NULL,
  train_number int4,
  type VARCHAR(20),
  manufacture_year CHAR(4),
  capacity int4,
  max_speed int4,
  Companycompany_id int4 NOT NULL,
  Routeroute_id int4 NOT NULL,
  PRIMARY KEY (train_id),
    CONSTRAINT "operates on" FOREIGN KEY (Routeroute_id) REFERENCES Route (route_id) ON DELETE SET NULL,
CONSTRAINT owns FOREIGN KEY (Companycompany_id) REFERENCES Company (company_id) ON DELETE RESTRICT
);


CREATE TABLE Schedule (
  schedule_id SERIAL NOT NULL,
  day_of_week CHAR(1),
  departure_time date,
  arrival_time date,
  status VARCHAR(20),
  Routeroute_id int4 NOT NULL,
  Traintrain_id int4 NOT NULL,
  PRIMARY KEY (schedule_id),
    CONSTRAINT "assinged to" FOREIGN KEY (Traintrain_id) REFERENCES Train (train_id),
    CONSTRAINT follows FOREIGN KEY (Routeroute_id) REFERENCES Route (route_id) ON DELETE SET NULL
);


CREATE TABLE "Train Trip" (
  trip_id SERIAL NOT NULL,
  departure_time date,
  arrival_time date,
  trip_status VARCHAR(20),
  delay_minutes int4,
  Routeroute_id int4 NOT NULL,
  Traintrain_id int4 NOT NULL,
  Employeeemployee_id int4 NOT NULL,
  EmployeePersonEMBG2 CHAR(13) NOT NULL,
  PlatformStationstation_id int4 NOT NULL,
  Platformplatform_id int4 NOT NULL,
  PRIMARY KEY (trip_id),
    CONSTRAINT assigned FOREIGN KEY (Traintrain_id) REFERENCES Train (train_id),
    CONSTRAINT drives FOREIGN KEY (EmployeePersonEMBG2, Employeeemployee_id) REFERENCES Employee (PersonEMBG, employee_id),

    CONSTRAINT "stops at" FOREIGN KEY (PlatformStationstation_id, Platformplatform_id) REFERENCES Platform (Stationstation_id, platform_id),
CONSTRAINT trip_follows FOREIGN KEY (Routeroute_id) REFERENCES Route (route_id)
);

CREATE TABLE Ticket (
  ticket_id SERIAL NOT NULL,
  seat_number int4,
  carriage_number int4,
  price NUMERIC(2, 0),
  ticket_status VARCHAR(20),
  Paymentpayment_id int4 NOT NULL,
  "Train Triptrip_id" int4 NOT NULL,
  Stationstation_id int4 NOT NULL,
  Stationstation_id2 int4 NOT NULL,
  PRIMARY KEY (ticket_id),
    CONSTRAINT ends_at FOREIGN KEY (Stationstation_id2) REFERENCES Station (station_id),
    CONSTRAINT "for" FOREIGN KEY ("Train Triptrip_id") REFERENCES "Train Trip" (trip_id) ON DELETE SET NULL,
    CONSTRAINT generates FOREIGN KEY (Paymentpayment_id) REFERENCES Payment (payment_id) ON DELETE CASCADE ,
    -- If a Payment is deleted, the Ticket is automatically removed because a ticket cannot exist without a valid financial record.
    CONSTRAINT starts_at FOREIGN KEY (Stationstation_id) REFERENCES Station (station_id)
);

CREATE TABLE "Train Service" (
  service_id int4 NOT NULL,
  service_type VARCHAR(20) NOT NULL,
  opening_time date NOT NULL,
  closing_time date NOT NULL,
  "Train Triptrip_id" int4 NOT NULL,
  Traintrain_id int4 NOT NULL,
CONSTRAINT includes FOREIGN KEY ("Train Triptrip_id") REFERENCES "Train Trip" (trip_id),
CONSTRAINT provides FOREIGN KEY (Traintrain_id) REFERENCES Train (train_id)
);


CREATE TABLE "Train Trip_Segment" (
  "Train Triptrip_id" int4 NOT NULL,
  Segmentsegment_id int4 NOT NULL,
  log_sequence_order int4 NOT NULL,
  PRIMARY KEY ("Train Triptrip_id", Segmentsegment_id),
    CONSTRAINT "FKTrain Trip986709" FOREIGN KEY (Segmentsegment_id) REFERENCES Segment (segment_id),
    CONSTRAINT "FKTrain Trip511043" FOREIGN KEY ("Train Triptrip_id") REFERENCES "Train Trip" (trip_id)
);

CREATE TABLE train_stops_at_station (
  Traintrain_id int4 NOT NULL,
  Stationstation_id int4 NOT NULL,
  PRIMARY KEY (Traintrain_id, Stationstation_id),
    CONSTRAINT FKtrain_stop896006 FOREIGN KEY (Stationstation_id) REFERENCES Station (station_id) ON DELETE RESTRICT,
    CONSTRAINT FKtrain_stop965689 FOREIGN KEY (Traintrain_id) REFERENCES Train (train_id) ON DELETE RESTRICT
);

CREATE TABLE Train_undergoes_Maintenance (
  Traintrain_id int4 NOT NULL,
  Maintenancemaintenance_id int4 NOT NULL,
  PRIMARY KEY (Traintrain_id, Maintenancemaintenance_id),
    CONSTRAINT FKTrain_unde536762 FOREIGN KEY (Maintenancemaintenance_id) REFERENCES Maintenance (maintenance_id) ON DELETE RESTRICT
);



--------Deleting tables-----------------

DROP TABLE IF EXISTS "Train Trip_Segment" CASCADE;

DROP TABLE IF EXISTS train_stops_at_station CASCADE;

DROP TABLE IF EXISTS Train_undergoes_Maintenance CASCADE;

DROP TABLE IF EXISTS "Employee_operates_Train Service" CASCADE;

DROP TABLE IF EXISTS Employee_performs_Maintenance CASCADE;

DROP TABLE IF EXISTS Route_Segment CASCADE;

DROP TABLE IF EXISTS "Train Service" CASCADE;

DROP TABLE IF EXISTS Ticket CASCADE;

DROP TABLE IF EXISTS Payment CASCADE;

DROP TABLE IF EXISTS Reservation CASCADE;

DROP TABLE IF EXISTS Schedule CASCADE;

DROP TABLE IF EXISTS "Train Trip" CASCADE;

DROP TABLE IF EXISTS Train CASCADE;

DROP TABLE IF EXISTS Maintenance CASCADE;

DROP TABLE IF EXISTS Segment CASCADE;

DROP TABLE IF EXISTS Platform CASCADE;

DROP TABLE IF EXISTS Passenger CASCADE;

DROP TABLE IF EXISTS Employee CASCADE;

DROP TABLE IF EXISTS Person CASCADE;

DROP TABLE IF EXISTS Route CASCADE;

DROP TABLE IF EXISTS Station CASCADE;

DROP TABLE IF EXISTS Company CASCADE;



-----------Altering tables--------------
ALTER TABLE payment
ALTER COLUMN amount TYPE NUMERIC(10, 2);

ALTER TABLE payment
ALTER COLUMN transaction_date TYPE TIMESTAMP;

ALTER TABLE payment ALTER COLUMN reservationreservation_id DROP NOT NULL;


ALTER TABLE Route
ALTER COLUMN route_name TYPE VARCHAR(100);

ALTER TABLE Segment
ADD COLUMN start_station_id int4,
ADD COLUMN end_station_id int4;

ALTER TABLE Segment
ADD CONSTRAINT fk_segment_start_station
FOREIGN KEY (start_station_id)
REFERENCES Station(station_id)
ON UPDATE CASCADE;

ALTER TABLE Segment
ADD CONSTRAINT fk_segment_end_station
FOREIGN KEY (end_station_id)
REFERENCES Station(station_id)
ON UPDATE CASCADE;

ALTER TABLE "Train Trip"
ADD COLUMN start_station_id int4,
ADD COLUMN end_station_id int4;

ALTER TABLE "Train Trip"
ADD CONSTRAINT fk_trip_start_station
FOREIGN KEY (start_station_id)
REFERENCES Station(station_id);

ALTER TABLE "Train Trip"
ADD CONSTRAINT fk_trip_end_station
FOREIGN KEY (end_station_id)
REFERENCES Station(station_id);