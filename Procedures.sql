-- CS4400: Introduction to Database Systems: Tuesday, September 12, 2023
-- Simple Airline Management System Course Project Mechanics [TEMPLATE] (v0)
-- Views, Functions & Stored Procedures

/* This is a standard preamble for most of our scripts.  The intent is to establish
a consistent environment for the database behavior. */
set global transaction isolation level serializable;
set global SQL_MODE = 'ANSI,TRADITIONAL';
set names utf8mb4;
set SQL_SAFE_UPDATES = 0;

set @thisDatabase = 'flight_tracking';
use flight_tracking;
-- -----------------------------------------------------------------------------
-- stored procedures and views
-- -----------------------------------------------------------------------------
/* Standard Procedure: If one or more of the necessary conditions for a procedure to
be executed is false, then simply have the procedure halt execution without changing
the database state. Do NOT display any error messages, etc. */

-- [_] supporting functions, views and stored procedures
-- -----------------------------------------------------------------------------
/* Helpful library capabilities to simplify the implementation of the required
views and procedures. */
-- -----------------------------------------------------------------------------
drop function if exists leg_time;
delimiter //
create function leg_time (ip_distance integer, ip_speed integer)
	returns time reads sql data
begin
	declare total_time decimal(10,2);
    declare hours, minutes integer default 0;
    set total_time = ip_distance / ip_speed;
    set hours = truncate(total_time, 0);
    set minutes = truncate((total_time - hours) * 60, 0);
    return maketime(hours, minutes, 0);
end //
delimiter ;

-- [1] add_airplane()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new airplane.  A new airplane must be sponsored
by an existing airline, and must have a unique tail number for that airline.
username.  An airplane must also have a non-zero seat capacity and speed. An airplane
might also have other factors depending on it's type, like skids or some number
of engines.  Finally, an airplane must have a new and database-wide unique location
since it will be used to carry passengers. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_airplane;
delimiter //
create procedure add_airplane (in ip_airlineID varchar(50), in ip_tail_num varchar(50),
	in ip_seat_capacity integer, in ip_speed integer, in ip_locationID varchar(50),
    in ip_plane_type varchar(100), in ip_skids boolean, in ip_propellers integer,
    in ip_jet_engines integer)
sp_main: begin
	-- Start transaction
    start transaction;
    
    if ip_airlineID IS NULL then rollback; leave sp_main; end if;
    if ip_tail_num IS NULL then rollback; leave sp_main; end if;
    
    -- Check if the airlineID is an existing airline
    if not exists (
        select 1
        from airline
        where airline.airlineID = ip_airlineID
    ) then 
        -- Rollback if condition fails
        rollback;
        leave sp_main; 
    end if;
    
    -- Check if the tail number is unique FOR that selected airline
    -- Tail number can be same for different airlines
    if exists (
        select 1
        from airplane
        where airlineID = ip_airlineID
        and tail_num = ip_tail_num
    ) then 
        -- Rollback if condition fails
        rollback;
        leave sp_main; 
    end if;

    -- Check for non-zero, non-null seat capacity and speed
    if ip_seat_capacity <= 0 or ip_speed <= 0 
    or ip_seat_capacity is NULL or ip_speed is NULL then 
        -- Rollback if condition fails
        rollback;
        leave sp_main; 
    end if;
    
    -- If airplane is a jet-driven airplane, check ip_jet_engines
    if ip_plane_type = 'jet' and ((ip_jet_engines <= 0 or ip_jet_engines is NULL)
    or ip_propellers is NOT NULL or ip_skids is NOT NULL) then 
        -- Rollback if condition fails
        rollback;
        leave sp_main; 
    end if;
    
    -- If airplane is a propeller-driven airplane, check ip_propellers
    if ip_plane_type = 'prop' and (ip_propellers <= 0 or ip_propellers is NULL
    or ip_skids <= 0 or ip_jet_engines is NOT NULL) then 
        -- Rollback if condition fails
        rollback;
        leave sp_main; 
    end if;
	    
     -- Check if the provided location is already in use in the database
    if exists (
        select 1
        from location
        where locationID = ip_locationID
    ) then 
        -- Rollback if condition fails
        rollback;
        leave sp_main; 
    end if;
    
    -- As the location is not in use, insert location to locationID
    insert into location (
		locationID
    ) values (
		ip_locationID
    );
    
    -- Insert the new airplane
    insert into airplane (
        airlineID,
        tail_num,
        seat_capacity,
        speed,
        locationID,
        plane_type,
        skids,
        propellers,
        jet_engines
    ) values (
        ip_airlineID,
        ip_tail_num,
        ip_seat_capacity,
        ip_speed,
        ip_locationID,
        ip_plane_type,
        ip_skids,
        ip_propellers,
        ip_jet_engines
    );
    
    -- Commit the transaction if no errors
    commit;
end //
delimiter ;

-- [2] add_airport()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new airport.  A new airport must have a unique
identifier along with a new and database-wide unique location if it will be used
to support airplane takeoffs and landings.  An airport may have a longer, more
descriptive name.  An airport must also have a city, state, and country designation. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_airport;
delimiter //
create procedure add_airport (in ip_airportID char(3), in ip_airport_name varchar(200),
    in ip_city varchar(100), in ip_state varchar(100), in ip_country char(3), in ip_locationID varchar(50))
sp_main: begin
	-- Start transaction
    START TRANSACTION;
    
	if exists (
        select 1
        from airport
        where airportID = ip_airportID
    ) then 
        -- Rollback if condition fails
        rollback;
        leave sp_main; 
    end if;

	if char_length(ip_airportID) > 3 or ip_airportID is null then
        -- Rollback if condition fails
        rollback;
        leave sp_main; 
    end if;
    
    
	if ip_city IS NULL then
        -- Rollback if condition fails
        rollback;
        leave sp_main; 
    end if;
    
	if  ip_state IS NULL then
        -- Rollback if condition fails
        rollback;
        leave sp_main; 
    end if;
    
	if char_length(ip_country) > 3 or ip_country IS NULL then
        -- Rollback if condition fails
        rollback;
        leave sp_main; 
    end if;

    if exists (
        select 1
        from location
        where locationID = ip_locationID
    ) then 
        -- Rollback if condition fails
        rollback;
        leave sp_main; 
    end if;

	insert into location (
		locationID
    ) values (
		ip_locationID
    );

	insert into airport  (
		airportID,
        airport_name,
        city,
        state,
        country,
        locationID
	) values (
		ip_airportID,
        ip_airport_name,
        ip_city,
        ip_state,
        ip_country,
        ip_locationID
	);
    
	-- Commit the transaction
    COMMIT;
end //
delimiter ;

-- [3] add_person()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new person.  A new person must reference a unique
identifier along with a database-wide unique location used to determine where the
person is currently located: either at an airport, or on an airplane, at any given
time.  A person must have a first name, and might also have a last name.

A person can hold a pilot role or a passenger role (exclusively).  As a pilot,
a person must have a tax identifier to receive pay, and an experience level.  As a
passenger, a person will have some amount of frequent flyer miles, along with a
certain amount of funds needed to purchase tickets for flights. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_person;
delimiter //
create procedure add_person (in ip_personID varchar(50), in ip_first_name varchar(100),
    in ip_last_name varchar(100), in ip_locationID varchar(50), in ip_taxID varchar(50),
    in ip_experience integer, in ip_miles integer, in ip_funds integer)
sp_main: begin
	-- Start transaction
    START TRANSACTION;
    
	-- Check if the person has a valid personID and first name
    if ip_personID is NULL or ip_first_name is NULL then rollback; leave sp_main; end if;
    
    -- Check if the person is a valid passenger
    if ip_taxID is NULL AND ip_experience is NULL
    AND (ip_miles < 0 or ip_funds < 0) then rollback; leave sp_main; end if;
    
    -- Check if the person is a valid pilot
    if ip_miles is NULL AND ip_funds is NULL
    AND (ip_taxID is NULL or ip_experience < 0) then rollback; leave sp_main; end if;
    
	-- Check if the provided location is already in use in the database
    if not exists (
        select 1
        from location
        where locationID = ip_locationID
    ) then rollback; leave sp_main; end if;
    
    IF ip_locationID IS NULL THEN
		leave sp_main;
	end if;

    -- If ip_taxID is not null and ip_experience is not null, check if person is pilot
    if ip_taxID is NOT NULL then
		-- If person has values for miles OR funds, rollback
		if ip_miles is NOT NULL or ip_funds is NOT NULL then 
				-- Rollback if condition fails
				rollback;
				leave sp_main;
		else
			-- Insert the new person
			insert into person (
				personID,
				first_name,
				last_name,
				locationID
			) values (
				ip_personID,
				ip_first_name,
				ip_last_name,
				ip_locationID
			);
            -- Add pilot to pilot table
            insert into pilot (
				personID,
				taxID,
				experience,
				commanding_flight
			) values (
				ip_personID,
				ip_taxID,
				ip_experience,
				NULL
			);
		end if;
	-- If ip_miles is not null and ip_funds is not null, check if person is passenger
    elseif ip_miles is NOT NULL and ip_funds is NOT NULL then
		-- If person has values for taxID and experience, rollback
		if ip_taxID is NOT NULL or ip_experience is NOT NULL then 
				-- Rollback if condition fails
				rollback;
				leave sp_main;
		else
			-- Insert the new person
			insert into person (
				personID,
				first_name,
				last_name,
				locationID
			) values (
				ip_personID,
				ip_first_name,
				ip_last_name,
				ip_locationID
			);
			 -- Add passenger to passenger table
            insert into passenger (
				personID,
				miles,
				funds
			) values (
				ip_personID,
				ip_miles,
				ip_funds
			);
		end if;
	else
		-- Invalid entry, rollback
		rollback;
		leave sp_main;
        end if;
        
    -- Commit the transaction
    COMMIT;
end //
delimiter ;

-- [4] grant_or_revoke_pilot_license()
-- -----------------------------------------------------------------------------
/* This stored procedure inverts the status of a pilot license.  If the license
doesn't exist, it must be created; and, if it laready exists, then it must be removed. */
-- -----------------------------------------------------------------------------
drop procedure if exists grant_or_revoke_pilot_license;
delimiter //
create procedure grant_or_revoke_pilot_license (in ip_personID varchar(50), in ip_license varchar(100))
sp_main: begin
	DECLARE license_exists INT DEFAULT 0;

    -- Start transaction
    START TRANSACTION;

	if ip_personID is null then rollback; leave sp_main; end if;
	if ip_license is null then rollback; leave sp_main; end if;
    
    
    -- Check if the pilot license exists
    SELECT COUNT(*) INTO license_exists 
    FROM pilot_licenses 
    WHERE personID = ip_personID AND license = ip_license;

    -- If the license exists, revoke it
    IF license_exists > 0 THEN 
        DELETE FROM pilot_licenses 
        WHERE personID = ip_personID AND license = ip_license;
    -- Otherwise, grant the license
    ELSE
        INSERT INTO pilot_licenses (personID, license)
        VALUES (ip_personID, ip_license);
    END IF;

    -- Commit the transaction
    COMMIT;
end //
delimiter ;

-- [5] offer_flight()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new flight.  The flight can be defined before
an airplane has been assigned for support, but it must have a valid route.  And
the airplane, if designated, must not be in use by another flight.  The flight
can be started at any valid location along the route except for the final stop,
and it will begin on the ground.  You must also include when the flight will
takeoff along with its cost. */
-- -----------------------------------------------------------------------------
drop procedure if exists offer_flight;
delimiter //
create procedure offer_flight (in ip_flightID varchar(50), in ip_routeID varchar(50),
    in ip_support_airline varchar(50), in ip_support_tail varchar(50), in ip_progress integer,
    in ip_next_time time, in ip_cost integer)
sp_main: begin
	DECLARE route_exists INT DEFAULT 0;

    -- Start transaction
    START TRANSACTION;
	
    if ip_routeID is null then rollback; leave sp_main; end if;
    if ip_flightID is null then rollback; leave sp_main; end if;
    
    -- Check for duplicate flightID
    if exists (select * from flight where flightID = ip_flightID) then rollback; leave sp_main; end if;
    
    -- Check if the route is valid
    SELECT COUNT(*) INTO route_exists 
    FROM route 
    WHERE routeID = ip_routeID;

    IF route_exists = 0 THEN 
        ROLLBACK;
        LEAVE sp_main;
    END IF;
    
    if (ip_support_airline is NULL AND ip_support_tail is NOT NULL)
    OR (ip_support_airline is NOT NULL AND ip_support_tail is NULL)
    then rollback; leave sp_main; end if;

	-- if whether the ip_support_airline and ip_support_tail is for a valid airplane
    IF NOT EXISTS(select * from airplane
    where airlineID = ip_support_airline AND tail_num = ip_support_tail
    AND ip_support_airline is NOT NULL 
    AND ip_support_tail is NOT NULL) then
        ROLLBACK;
	    LEAVE sp_main;
    END IF;
    
    -- if whether there is already a flight with that airplane
    IF EXISTS(select * from flight
    where support_airline = ip_support_airline AND support_tail = ip_support_tail) then
        ROLLBACK;
	    LEAVE sp_main;
    END IF;
    
    -- Check if progress value is valid and if flight is in the final stop
    -- As the flight will always start on_ground, all we have to check is if the plane is
    -- in the final airport of the route
    IF ip_progress < 0 or ip_progress >= (select max(sequence) from route_path where routeID = ip_routeID) then
		rollback;
        leave sp_main;
	END IF;
    
    -- Check if cost value is valid
    IF ip_cost < 0 then
		rollback;
        leave sp_main;
	END IF;

    -- Insert the new flight
    INSERT INTO flight (flightID, routeID, support_airline, support_tail, progress, airplane_status, next_time, cost)
    VALUES (ip_flightID, ip_routeID, ip_support_airline, ip_support_tail, ip_progress, 'on_ground', ip_next_time, ip_cost);

    -- Commit the transaction
    COMMIT;
end //
delimiter ;

-- [6] flight_landing()
-- -----------------------------------------------------------------------------
/* This stored procedure updates the state for a flight landing at the next airport
along it's route.  The time for the flight should be moved one hour into the future
to allow for the flight to be checked, refueled, restocked, etc. for the next leg
of travel.  Also, the pilots of the flight should receive increased experience, and
the passengers should have their frequent flyer miles updated. */
-- -----------------------------------------------------------------------------
drop procedure if exists flight_landing;
delimiter //
create procedure flight_landing (in ip_flightID varchar(50))
sp_main: begin
	declare add_miles int default 0;
    declare curr_legID varchar(50);
    declare curr_routeID varchar(50);
    declare curr_airlineID varchar(50);
    declare curr_tail varchar(50);
    declare curr_airplaneID varchar(50);
    declare curr_apLocID varchar(50);
    DECLARE curr_progress integer;
    
    
	-- Start transaction
    START TRANSACTION;
    
    if ip_flightID is null then rollback; leave sp_main; end if;
    
    -- Check if airplane is on_ground
    if (select airplane_status from flight where ip_flightID = flightID) = 'on_ground'
    then rollback; leave sp_main; end if;
    
    update flight set airplane_status = 'on_ground' where flightID = ip_flightID and airplane_status = 'in_flight';
    
    update flight set next_time = ADDTIME(next_time, '01:00:00') where flightID = ip_flightID;

    -- Increase experience for pilots
	update pilot set experience = experience + 1 where commanding_flight = ip_flightID;
    
    -- Set curr_routeID as the routeID of the current flight
    select routeID into curr_routeID from flight where flightID = ip_flightID;
    select progress into curr_progress from flight where flightID = ip_flightID;
    
    -- Check if progress is valid
	if curr_progress < 0 or curr_progress > (select max(sequence) from route_path where routeID = curr_routeID)
    then rollback; leave sp_main; end if;
    
    -- Set curr_legID as the legID of the current route where flight.progress = route.sequence
    select legID into curr_legID from route_path 
    where routeID = curr_routeID AND sequence = (SELECT progress FROM flight WHERE flightID = ip_flightID);
    
    -- Check if leg distances of flight is valid
    if (select distance from leg where legID = curr_legID) < 0 then rollback; leave sp_main; end if;
    
    -- Set add_miles as the distance of curr_legID
    select distance into add_miles from leg
    where legID = curr_legID;
    
	select support_airline into curr_airlineID from flight
    where flightID = ip_flightID;
    
    select support_tail into curr_tail from flight
    where flightID = ip_flightID;
    
	-- Check if curr_airlineID and curr_tail are valid values
	if (curr_airlineID is NULL AND curr_tail is NOT NULL)
    OR (curr_airlineID is NOT NULL AND curr_tail is NULL)
    OR (curr_airlineID is NULL AND curr_tail is NULL)
    then rollback; leave sp_main; end if;
    
    -- Set curr_apLocID as the locationID of curr_airplane
    select locationID into curr_apLocID from airplane
    where airlineID = curr_airlineID and tail_num = curr_tail;
    
    -- Update frequent flyer miles for passengers
    update passenger
    set miles = miles + add_miles
    where personID IN (select personID from person where locationID = curr_apLocID);
    
	-- Commit the transaction
    COMMIT;
end //
delimiter ;

-- [7] flight_takeoff()
-- -----------------------------------------------------------------------------
/* This stored procedure updates the state for a flight taking off from its current
airport towards the next airport along it's route.  The time for the next leg of
the flight must be calculated based on the distance and the speed of the airplane.
And we must also ensure that propeller driven planes have at least one pilot
assigned, while jets must have a minimum of two pilots. If the flight cannot take
off because of a pilot shortage, then the flight must be delayed for 30 minutes. */
-- -----------------------------------------------------------------------------
drop procedure if exists flight_takeoff;
delimiter //
create procedure flight_takeoff (in ip_flightID varchar(50))
sp_main: begin
    DECLARE v_speed INT;
    DECLARE v_distance INT;
    DECLARE v_time_required INT;
    DECLARE v_pilot_count INT;
    DECLARE curr_progress INT;
    DECLARE v_plane_type VARCHAR(100);
    declare curr_legID varchar(50);
    declare curr_routeID varchar(50);
	declare curr_airlineID varchar(50);
    declare curr_tail varchar(50);
    
	-- Start transaction
    START TRANSACTION;

	if ip_flightID is null then rollback; leave sp_main; end if;
    -- Check if the flight is currently in_flight
    if (select airplane_status from flight where flightID = ip_flightID) = 'in_flight' 
	then rollback; leave sp_main; end if;
    
	-- Set curr_routeID as the routeID of the current flight
    select routeID into curr_routeID from flight where flightID = ip_flightID;
    select progress into curr_progress from flight where flightID = ip_flightID;
    
    -- Check if progress is valid
	if curr_progress < 0 or curr_progress >= (select max(sequence) from route_path where routeID = curr_routeID)
    then rollback; leave sp_main; end if;
    
    -- Set curr_legID as the legID of the current route where flight.progress = route.sequence
    select legID into curr_legID from route_path 
    where routeID = curr_routeID AND sequence = (SELECT progress FROM flight WHERE flightID = ip_flightID);

	select support_airline into curr_airlineID from flight
    where flightID = ip_flightID;
    
    select support_tail into curr_tail from flight
    where flightID = ip_flightID;
    
    -- Check if curr_airlineID and curr_tail are valid values
	if (curr_airlineID is NULL AND curr_tail is NOT NULL)
    OR (curr_airlineID is NOT NULL AND curr_tail is NULL)
    OR (curr_airlineID is NULL AND curr_tail is NULL)
    then rollback; leave sp_main; end if;

    -- Get the speed of the airplane for the flight
	SELECT speed INTO v_speed
	FROM airplane
	WHERE airlineID = curr_airlineID AND  tail_num = curr_tail;
    
	-- Check if speed of airplane is valid; assuming speed = 0 is INVALID!
    if v_speed <= 0 then rollback; leave sp_main; end if;

    -- Get the distance of the next leg of the flight
    SELECT distance INTO v_distance FROM leg where legID = curr_legID;
    
    -- Check if distance of leg is valid; assuming distance = 0 is INVALID!
    if v_distance <= 0 then rollback; leave sp_main; end if;

    -- Calculate the time required for the next leg of the flight
    SET v_time_required = v_distance / v_speed;

    -- Get the type of the airplane for the flight
    SELECT plane_type INTO v_plane_type
    FROM airplane
    WHERE airlineID = curr_airlineID AND  tail_num = curr_tail;

    -- Get the count of pilots for the flight
    SELECT COUNT(*) INTO v_pilot_count
    FROM pilot
    WHERE commanding_flight = ip_flightID;

    -- Check if there are enough pilots for the flight
    IF v_plane_type = 'jet' AND v_pilot_count < 2 THEN
        -- Delay the flight for 30 minutes
        UPDATE flight
        SET 
			next_time = ADDTIME(next_time, SEC_TO_TIME(0.5*3600)),
            airplane_status = 'on_ground'
            where flightID = ip_flightID;
    ELSEIF v_plane_type = 'propeller' AND v_pilot_count < 1 THEN
        -- Delay the flight for 30 minutes
        UPDATE flight
        SET next_time = ADDTIME(next_time, SEC_TO_TIME(0.5*3600)),
        airplane_status = 'on_ground'
        where flightID = ip_flightID;
    ELSE
        -- Update the flight progress and next_time
        IF (select sequence from route_path where routeID = curr_routeID) = (select progress from flight where flightId = ip_flightID)
        then 
			rollback;
            leave sp_main;
	    ELSE
			UPDATE flight
			SET 
				progress = progress + 1,
				next_time = ADDTIME(next_time, SEC_TO_TIME(v_time_required * 3600)),
				airplane_status = 'in_flight'
			WHERE flightID = ip_flightID;
			END IF;
    END IF;
	
    -- Commit the transaction
    COMMIT;
end //
delimiter ;

-- [8] passengers_board()
-- -----------------------------------------------------------------------------
/* This stored procedure updates the state for passengers getting on a flight at
its current airport.  The passengers must be at the same airport as the flight,
and the flight must be heading towards that passenger's desired destination.
Also, each passenger must have enough funds to cover the flight.  Finally, there
must be enough seats to accommodate all boarding passengers. */
-- -----------------------------------------------------------------------------
drop procedure if exists passengers_board;
delimiter //
create procedure passengers_board (in ip_flightID varchar(50))
sp_main: begin
	DECLARE curr_legID VARCHAR(50);
    DECLARE curr_routeID VARCHAR(50);
    DECLARE curr_airline VARCHAR(50);
    DECLARE curr_tailnum VARCHAR(50);
	DECLARE curr_progress INTEGER;
    DECLARE curr_cost INTEGER;
    DECLARE curr_flightDeparture CHAR(3);
    DECLARE curr_flightArrival CHAR(3);
    DECLARE curr_airplaneID VARCHAR(50);
    
    -- Start transaction
    START TRANSACTION;
    
    -- Check if ip_flightID is valid
    if not exists(select * from flight where flightID = ip_flightID)
    or ip_flightID is null then rollback; leave sp_main; end if;
    
	-- Check if the flight is not on_ground, leave transaction
    IF (SELECT airplane_status FROM flight WHERE flightID = ip_flightID) != 'on_ground'
    THEN rollback; leave sp_main; end if;

	-- Set curr_routeID, curr_airline, curr_tailnum as routeID, support_airline, support_tail of current flight
    select routeID, support_airline, support_tail, cost into curr_routeID, curr_airline, curr_tailnum, curr_cost
    from flight where flightID = ip_flightID;
    select progress into curr_progress from flight where flightID = ip_flightID;
    
    -- Check if progress is valid
	if curr_progress < 0 or curr_progress > (select max(sequence) from route_path where routeID = curr_routeID)
    then rollback; leave sp_main; end if;
    
	-- Check if curr_airlineID and curr_tail are valid values
	if (curr_airline is NULL AND curr_tailnum is NOT NULL)
    OR (curr_airline is NOT NULL AND curr_tailnum is NULL)
    OR (curr_airline is NULL AND curr_tailnum is NULL)
    then rollback; leave sp_main; end if;
    
    -- Set curr_legID as the legID of the current route where flight.progress = route.sequence
    select legID into curr_legID from route_path 
    where routeID = curr_routeID and sequence = (select progress from flight where flightID = ip_flightID);
	
    -- Check if leg distances of flight is valid
    if (select distance from leg where legID = curr_legID) < 0 then rollback; leave sp_main; end if;
    
    -- Set curr_flightDeparture / curr_flightArrival as the starting /ending airport
    select departure, arrival into curr_flightDeparture, curr_flightArrival from leg
    where legID = curr_legID;
    
    -- Set curr_airplaneID as locationID of airplane for flight
    select locationID into curr_airplaneID from airplane 
    where airplane.airlineID = curr_airline and airplane.tail_num = curr_tailnum;

	-- Update passenger and person based on conditions
    -- 1) person is a passenger with enough funds
    -- 2) passenger is at departing airport
    -- 3) passenger is not at end of vacation
    -- 4) passenger's imm next dest is arrival of leg
   UPDATE 
        person AS per, passenger AS pass, airline as al
    SET 
        per.locationID = curr_airplaneID, 
        pass.funds = pass.funds - curr_cost,
        al.revenue = al.revenue + curr_cost
    WHERE 
		per.personID = pass.personID 
        AND pass.funds >= curr_cost
        AND al.airlineID = curr_airline
        AND per.locationID = curr_flightDeparture
        AND per.personID IN (
            SELECT DISTINCT pv1.personID
            FROM passenger_vacations pv1
            JOIN passenger_vacations pv2 ON pv1.personID = pv2.personID
            WHERE pv2.sequence = pv1.sequence + 1
            AND pv1.airportID = curr_flightDeparture
            AND pv2.airportID = curr_flightArrival
        );
	
    -- Commit the transaction
    COMMIT;
end //
delimiter ;

-- [9] passengers_disembark()
-- -----------------------------------------------------------------------------
/* This stored procedure updates the state for passengers getting off of a flight
at its current airport. The passengers must be on that flight, and the flight must
be located at the destination airport as referenced by the ticket. */
-- -----------------------------------------------------------------------------
drop procedure if exists passengers_disembark;
delimiter //
create procedure passengers_disembark (in ip_flightID varchar(50))
sp_main: begin
    DECLARE curr_legID VARCHAR(50);
    DECLARE curr_routeID VARCHAR(50);
    DECLARE curr_progress INT;
    DECLARE curr_flightArrival CHAR(3);
    DECLARE curr_airplaneID VARCHAR(50);
    DECLARE curr_airline VARCHAR(50);
    DECLARE curr_tailnum VARCHAR(50);

    -- Start transaction
    START TRANSACTION;
    
    -- Set curr_routeID, curr_airline, curr_tailnum as routeID, support_airline, support_tail of current flight
    select routeID, support_airline, support_tail into curr_routeID, curr_airline, curr_tailnum
    from flight where flightID = ip_flightID;
    select progress into curr_progress from flight where flightID = ip_flightID;
    
    
    -- Check if progress is valid
	if curr_progress < 0 or curr_progress > (select max(sequence) from route_path where routeID = curr_routeID)
    then rollback; leave sp_main; end if;
    
	-- Check if curr_airlineID and curr_tail are valid values
	if (curr_airline is NULL AND curr_tailnum is NOT NULL)
    OR (curr_airline is NOT NULL AND curr_tailnum is NULL)
    OR (curr_airline is NULL AND curr_tailnum is NULL)
    then rollback; leave sp_main; end if;
    
    -- Check if ip_flightID is valid
    if not exists(select * from flight where flightID = ip_flightID)
    or ip_flightID is null then rollback; leave sp_main; end if;
    
    -- Check if the flight is not on_ground, leave transaction
    IF (SELECT airplane_status FROM flight WHERE flightID = ip_flightID) != 'on_ground'
    THEN rollback; leave sp_main; end if;
    
    -- Set curr_legID as the legID of the current route where flight.progress = route.sequence
    SELECT legID INTO curr_legID FROM route_path 
    WHERE routeID = curr_routeID AND sequence = (SELECT progress FROM flight WHERE flightID = ip_flightID);

    -- Set curr_flightArrival as the ending airport
    SELECT arrival INTO curr_flightArrival FROM leg
    WHERE legID = curr_legID;

    -- Set curr_airplaneID as the locationID of the airplane for the flight
    SELECT locationID INTO curr_airplaneID FROM airplane 
    WHERE tail_num = (SELECT support_tail FROM flight WHERE flightID = ip_flightID)
    AND airlineID = (SELECT support_airline FROM flight WHERE flightID = ip_flightID);

    -- Update passenger and person based on conditions
    UPDATE person AS per
    JOIN passenger_vacations AS pv ON per.personID = pv.personID
    SET per.locationID = (SELECT locationID FROM airport WHERE airportID = curr_flightArrival)
    WHERE per.locationID = curr_airplaneID
    AND pv.airportID = curr_flightArrival
    AND pv.sequence = (SELECT MIN(pv2.sequence) 
                        FROM passenger_vacations AS pv2
                        WHERE pv2.personID = pv.personID
                        AND pv2.airportID = curr_flightArrival
                        AND pv2.sequence > (SELECT COALESCE(MAX(pv3.sequence), 0) 
                                            FROM passenger_vacations AS pv3
                                            WHERE pv3.personID = pv.personID
                                            AND pv3.sequence < pv.sequence));

    -- Commit the transaction
    COMMIT;
end //
delimiter ;

-- [10] assign_pilot()
-- -----------------------------------------------------------------------------
/* This stored procedure assigns a pilot as part of the flight crew for a given
flight.  The pilot being assigned must have a license for that type of airplane,
and must be at the same location as the flight.  Also, a pilot can only support
one flight (i.e. one airplane) at a time.  The pilot must be assigned to the flight
and have their location updated for the appropriate airplane. */
-- -----------------------------------------------------------------------------
drop procedure if exists assign_pilot;
delimiter //
create procedure assign_pilot (in ip_flightID varchar(50), ip_personID varchar(50))
sp_main: begin
	DECLARE curr_plane_type VARCHAR(100);
	DECLARE curr_airlineID varchar(50);
	DECLARE curr_tail varchar(50);
	DECLARE assigned_flight VARCHAR(50);
	DECLARE person_locationID VARCHAR(50);
	DECLARE airplane_locationID VARCHAR(50);
	DECLARE flight_locationID VARCHAR(50);
	DECLARE curr_routeID VARCHAR(50);
	DECLARE curr_legID VARCHAR(50);
	DECLARE curr_progress INT;
    
    -- Start transaction
    START TRANSACTION;
    
    -- Check if ip_flightID is valid
    if not exists(select * from flight where flightID = ip_flightID)
    or ip_flightID is null then rollback; leave sp_main; end if;
    
    -- Check if ip_personID is valid
    if not exists(select * from person where personID = ip_personID)
    or ip_personID is null or not exists(select * from pilot where personID = ip_personID)
    then rollback; leave sp_main; end if;
    
	-- Set curr_routeID, progress as the routeID of the current flight
	select routeID into curr_routeID from flight where flightID = ip_flightID;
	select progress into curr_progress from flight where flightID = ip_flightID;
    
	-- Check if progress of flight is valid
    -- if flight finish, we don't need to assign the pilot.
    if curr_progress < 0 or curr_progress >= (select max(sequence) from route_path where routeID = curr_routeID)
    then rollback; leave sp_main; end if;
    
	-- find legID for current flight 
	select legID into curr_legID from route_path 
	where routeID = curr_routeID AND sequence = curr_progress;

	select support_airline into curr_airlineID from flight
	where flightID = ip_flightID;
		
	select support_tail into curr_tail from flight
	where flightID = ip_flightID;
    
    -- Check if curr_airlineID and curr_tail are valid values
	if (curr_airlineID is NULL AND curr_tail is NOT NULL)
    OR (curr_airlineID is NOT NULL AND curr_tail is NULL)
    OR (curr_airlineID is NULL AND curr_tail is NULL)
    then rollback; leave sp_main; end if;

	-- find flight_location
	select locationID into flight_locationID
	from airport 
	where airportID = (select arrival from leg where legID = curr_legID);

	-- find assigned flight for pliot
	select commanding_flight into assigned_flight
	from pilot where personID = ip_personID;

	-- if flight already started, we don't need to assign the pliot.
	IF (select airplane_status from flight where flightID = ip_flightID) = 'in_flight' then
		rollback;
		leave sp_main;
	END IF;

	-- if pilot already was assigned , leave main
	IF  (assigned_flight IS NOT NULL) then 
		rollback;
		leave sp_main;
	END IF;

	select locationID into person_locationID
	from person where personID = ip_personID;

	select locationID into airplane_locationID
	from airplane where airlineID = curr_airlineID AND tail_num = curr_tail;

	IF airplane_locationID IS NULL then
		rollback;
		leave sp_main;
	END IF;

	SELECT plane_type INTO curr_plane_type
	FROM airplane
	WHERE airlineID = curr_airlineID AND  tail_num = curr_tail;

	IF EXISTS (select * from pilot_licenses where personID = ip_personID AND license = curr_plane_type) THEN
		IF (person_locationID = flight_locationID) THEN
				update pilot 
				set commanding_flight = ip_flightID
				where personID = ip_personID;

				update person
				set locationID = airplane_locationID
				where personID = ip_personID;
		ELSE
			rollback;
			leave sp_main;
		END IF;
	ELSE -- if don't exist pilot
		rollback;
		leave sp_main;
	END IF;
    -- Commit the transaction
    COMMIT;
end //
delimiter ;

-- [11] recycle_crew()
-- -----------------------------------------------------------------------------
/* This stored procedure releases the assignments for a given flight crew.  The
flight must have ended, and all passengers must have disembarked. */
-- -----------------------------------------------------------------------------
drop procedure if exists recycle_crew;
delimiter //
create procedure recycle_crew (in ip_flightID varchar(50))
sp_main: begin
	DECLARE flight_ended BOOLEAN DEFAULT FALSE;
    DECLARE passengers_disembarked BOOLEAN DEFAULT FALSE;
    DECLARE arrival_airport_locationID VARCHAR(50);
    
    -- Start transaction
    START TRANSACTION;
    
    -- Check if ip_flightID is valid
    if not exists(select * from flight where flightID = ip_flightID)
    or ip_flightID is null then rollback; leave sp_main; end if;

    -- Check for on_ground and if flight is in final destination
    SELECT
        (f.airplane_status = 'on_ground' AND f.progress = rp.max_sequence)
    INTO
        flight_ended
    FROM
        flight AS f
    JOIN
        (SELECT routeID, MAX(sequence) AS max_sequence FROM route_path GROUP BY routeID) AS rp
    ON
        f.routeID = rp.routeID
    WHERE
        f.flightID = ip_flightID;
        
	-- If flight did not end, don't update
    if flight_ended = false then rollback; leave sp_main; end if;

    -- Check for no passengers
    SELECT
        NOT EXISTS (
            SELECT 1 FROM passenger
            WHERE personID IN (
                SELECT personID FROM person
                WHERE locationID = (SELECT locationID FROM airplane 
                WHERE tail_num = (SELECT support_tail FROM flight WHERE flightID = ip_flightID)
                AND airlineID = (SELECT support_airline FROM flight WHERE flightID = ip_flightID))
            )
        )
    INTO
        passengers_disembarked;
	
    -- If there are still passengers on board, don't update
    if passengers_disembarked = false then rollback; leave sp_main; end if;
    
    -- Determine the arrival airport's locationID
    SELECT a.locationID INTO arrival_airport_locationID
    FROM flight AS f
    JOIN leg AS l ON l.legID = (SELECT legID FROM route_path WHERE routeID = f.routeID AND sequence = f.progress)
    JOIN airport AS a ON l.arrival = a.airportID
    WHERE f.flightID = ip_flightID;
    
    -- Release the pilot assignments
	UPDATE pilot SET commanding_flight = NULL WHERE commanding_flight = ip_flightID;

	-- Update the location of all passengers
	UPDATE person SET locationID = arrival_airport_locationID
	WHERE locationID IN (
		SELECT locationID FROM airplane WHERE tail_num = (SELECT support_tail FROM flight WHERE flightID = ip_flightID)
        AND airlineID = (SELECT support_airline FROM flight WHERE flightID = ip_flightID)
	);
    -- Commit the transaction
    COMMIT;
end //
delimiter ;

-- [12] retire_flight()
-- -----------------------------------------------------------------------------
/* This stored procedure removes a flight that has ended from the system.  The
flight must be on the ground, and either be at the start its route, or at the
end of its route.  And the flight must be empty - no pilots or passengers. */
-- -----------------------------------------------------------------------------
drop procedure if exists retire_flight;
delimiter //
create procedure retire_flight (in ip_flightID varchar(50))
sp_main: begin
	declare	curr_progress integer;
	declare curr_routeID varchar(50);
	declare curr_airline varchar(50);
    declare curr_tailnum varchar(50);
    declare curr_airplaneID varchar(50);

    -- Start transaction
    START TRANSACTION;
    
    -- Check if ip_flightID is valid
    if not exists(select * from flight where flightID = ip_flightID)
    or ip_flightID is null then rollback; leave sp_main; end if;

	-- Set curr_routeID, curr_airline, curr_tailnum as routeID, support_airline, support_tail of current flight
    select routeID, support_airline, support_tail into curr_routeID, curr_airline, curr_tailnum
    from flight where flightID = ip_flightID;
    select progress into curr_progress from flight where flightID = ip_flightID;
    
    -- Check if progress is valid
	if curr_progress < 0 or curr_progress > (select max(sequence) from route_path where routeID = curr_routeID)
    then rollback; leave sp_main; end if;
    
    -- Check if curr_airlineID and curr_tail are valid values
	if (curr_airline is NULL AND curr_tailnum is NOT NULL)
    OR (curr_airline is NOT NULL AND curr_tailnum is NULL)
    OR (curr_airline is NULL AND curr_tailnum is NULL)
    then rollback; leave sp_main; end if;
    
	select locationID into curr_airplaneID
	from airplane where airlineID = curr_airline and tail_num = curr_tailnum;

    -- Check if the flight is not on_ground, leave transaction
    if (select airplane_status from flight where flightID = ip_flightID) != 'on_ground' then rollback; leave sp_main; end if;
    
    -- Check if the sequence of the flight is not 0 and not last sequence, if it is not, leave transaction
    if curr_progress != 0
    and (select max(sequence) from route_path where routeID = curr_routeID) != (select progress from flight where flightId = ip_flightID)
    then rollback; leave sp_main; end if;
    
    -- Check if the flight is empty, if it is not, leave transaction
    if (select count(*) from person where locationID = curr_airplaneID) != 0
    and curr_airplaneID is not null
    then rollback; leave sp_main; end if;
    
    -- Delete flight
    delete from flight where flightID = ip_flightID;
    -- Commit the transaction
    COMMIT;
end //
delimiter ;

-- [13] simulation_cycle()
-- -----------------------------------------------------------------------------
/* This stored procedure executes the next step in the simulation cycle.  The flight
with the smallest next time in chronological order must be identified and selected.
If multiple flights have the same time, then flights that are landing should be
preferred over flights that are taking off.  Similarly, flights with the lowest
identifier in alphabetical order should also be preferred.

If an airplane is in flight and waiting to land, then the flight should be allowed
to land, passengers allowed to disembark, and the time advanced by one hour until
the next takeoff to allow for preparations.

If an airplane is on the ground and waiting to takeoff, then the passengers should
be allowed to board, and the time should be advanced to represent when the airplane
will land at its next location based on the leg distance and airplane speed.

If an airplane is on the ground and has reached the end of its route, then the
flight crew should be recycled to allow rest, and the flight itself should be
retired from the system. */
-- -----------------------------------------------------------------------------
drop procedure if exists simulation_cycle;
delimiter //
create procedure simulation_cycle ()
sp_main: begin
	DECLARE ip_flightID VARCHAR(50);
    DECLARE next_flight_status VARCHAR(100);
    DECLARE next_flight_progress INT;
    DECLARE end_flight BOOLEAN DEFAULT FALSE;
    
    -- Start transaction
    START TRANSACTION;

    -- Find the next flight to process
    SELECT f.flightID, f.airplane_status, f.progress 
    INTO ip_flightID, next_flight_status, next_flight_progress
    FROM flight AS f
    ORDER BY f.next_time ASC, f.airplane_status DESC, f.flightID ASC
    LIMIT 1;
    
    -- Check if next flight is valid
    if ip_flightID is null then rollback; leave sp_main; end if;
    
    -- Check if next flight is at end of route
    select (select max(sequence) from route_path rp where f.routeID = rp.routeID) = (select progress from flight where flightId = ip_flightID)
    into end_flight from flight f
    where flightID = ip_flightID;

    -- Process the flight
    IF next_flight_status = 'in_flight' THEN
        -- Flight is in flight and waiting to land
        CALL flight_landing(ip_flightID);
        CALL passengers_disembark(ip_flightID);
    ELSEIF next_flight_status = 'on_ground' AND end_flight = FALSE THEN
        -- Flight is on ground and waiting to takeoff
        CALL passengers_board(ip_flightID);
        CALL flight_takeoff(ip_flightID);
	ELSEIF next_flight_status = 'on_ground' AND end_flight = TRUE THEN
        -- Flight is on the ground and has reached the end of its route
        CALL recycle_crew();
        CALL retire_flight();
    END IF;
    
	-- Commit the transaction
    COMMIT;
end //
delimiter ;

-- [14] flights_in_the_air()
-- -----------------------------------------------------------------------------
/* This view describes where flights that are currently airborne are located. */
-- -----------------------------------------------------------------------------
create or replace view flights_in_the_air (departing_from, arriving_at, num_flights,
	flight_list, earliest_arrival, latest_arrival, airplane_list) as
SELECT 
    (SELECT airportID FROM airport WHERE airportID = dep_leg.departure) AS departing_from,
    (SELECT airportID FROM airport WHERE airportID = arr_leg.arrival) AS arriving_at,
    COUNT(DISTINCT f.flightID) AS num_flights,
    GROUP_CONCAT(DISTINCT f.flightID ORDER BY f.flightID ASC SEPARATOR ', ') AS flight_list,
    MIN(f.next_time) AS earliest_arrival,
    MAX(f.next_time) AS latest_arrival,
    GROUP_CONCAT(DISTINCT a.locationID ORDER BY a.locationID ASC SEPARATOR ', ') AS airplane_list
FROM
    flight f
    INNER JOIN airplane a ON f.support_airline = a.airlineID and f.support_tail = a.tail_num
    INNER JOIN route_path rp1 ON (f.routeID = rp1.routeID AND rp1.sequence = f.progress)
    INNER JOIN leg dep_leg ON rp1.legID = dep_leg.legID
    INNER JOIN leg arr_leg ON rp1.legID = arr_leg.legID
WHERE
    f.airplane_status = 'in_flight'
GROUP BY
    dep_leg.departure, arr_leg.arrival;


-- [15] flights_on_the_ground()
-- -----------------------------------------------------------------------------
/* This view describes where flights that are currently on the ground are located. */
-- This view describes where flights that are currently on the ground are located.
-- We need to display what airports these flights are departing from,
-- how many flights are departing from each airport,
-- the list of flights departing from each airport,
-- the earliest and latest arrival time amongst all of these flights at each airport,
-- and the list of planes (by their location id) that are departing from each airport.
-- -----------------------------------------------------------------------------
create or replace view flights_on_the_ground (departing_from, num_flights,
	flight_list, earliest_arrival, latest_arrival, airplane_list) as 
SELECT 
    (SELECT airportID FROM airport WHERE airportID = dep_leg.arrival) AS departing_from,
    COUNT(DISTINCT f.flightID) AS num_flights,
    GROUP_CONCAT(DISTINCT f.flightID ORDER BY f.flightID ASC SEPARATOR ', ') AS flight_list,
    MIN(f.next_time) AS earliest_arrival,
    MAX(f.next_time) AS latest_arrival,
    GROUP_CONCAT(DISTINCT a.locationID ORDER BY a.locationID ASC SEPARATOR ', ') AS airplane_list
FROM
    flight f
    INNER JOIN airplane a ON f.support_airline = a.airlineID and f.support_tail = a.tail_num
    INNER JOIN route_path rp1 ON (f.routeID = rp1.routeID AND rp1.sequence = f.progress)
    INNER JOIN leg dep_leg ON rp1.legID = dep_leg.legID
WHERE
    f.airplane_status = 'on_ground'
GROUP BY
    dep_leg.arrival
UNION
SELECT 
    (SELECT airportID FROM airport WHERE airportID = dep_leg.departure) AS departing_from,
    COUNT(DISTINCT f.flightID) AS num_flights,
    GROUP_CONCAT(DISTINCT f.flightID ORDER BY f.flightID ASC SEPARATOR ', ') AS flight_list,
    MIN(f.next_time) AS earliest_arrival,
    MAX(f.next_time) AS latest_arrival,
    GROUP_CONCAT(DISTINCT a.locationID ORDER BY a.locationID ASC SEPARATOR ', ') AS airplane_list
FROM
    flight f
    INNER JOIN airplane a ON f.support_airline = a.airlineID and f.support_tail = a.tail_num
    INNER JOIN route_path rp1 ON (f.routeID = rp1.routeID AND rp1.sequence = f.progress + 1)
    INNER JOIN leg dep_leg ON rp1.legID = dep_leg.legID
WHERE
    f.airplane_status = 'on_ground'
GROUP BY
    dep_leg.departure;

-- [16] people_in_the_air()
-- -----------------------------------------------------------------------------
/* This view describes where people who are currently airborne are located. */
-- -----------------------------------------------------------------------------
create or replace view people_in_the_air (departing_from, arriving_at, num_airplanes,
	airplane_list, flight_list, earliest_arrival, latest_arrival, num_pilots,
	num_passengers, joint_pilots_passengers, person_list) as
SELECT 
    (SELECT airportID FROM airport WHERE airportID = dep_leg.departure) AS departing_from,
    (SELECT airportID FROM airport WHERE airportID = arr_leg.arrival) AS arriving_at,
    COUNT(DISTINCT a.locationID) AS num_airplanes,
    GROUP_CONCAT(DISTINCT a.locationID ORDER BY a.locationID ASC SEPARATOR ', ') AS airplane_list,
    GROUP_CONCAT(DISTINCT f.flightID ORDER BY f.flightID ASC SEPARATOR ', ') AS flight_list,
    MIN(f.next_time) AS earliest_arrival,
    MAX(f.next_time) AS latest_arrival,
    COUNT(DISTINCT CASE WHEN pl.personID IS NOT NULL THEN pl.personID END) AS num_pilots,
    COUNT(DISTINCT CASE WHEN pa.personID IS NOT NULL THEN pa.personID END) AS num_passengers,
    COUNT(DISTINCT p.personID) AS joint_pilots_passengers,
    GROUP_CONCAT(DISTINCT p.personID ORDER BY p.personID ASC SEPARATOR ', ') AS person_list
FROM
    flight f
    INNER JOIN airplane a ON f.support_airline = a.airlineID and f.support_tail = a.tail_num
    INNER JOIN person p ON a.locationID = p.locationID
    LEFT JOIN pilot pl ON pl.personID = p.personID
    LEFT JOIN passenger pa ON pa.personID = p.personID
    INNER JOIN route_path rp1 ON (f.routeID = rp1.routeID AND rp1.sequence = f.progress)
    INNER JOIN leg dep_leg ON rp1.legID = dep_leg.legID
    INNER JOIN leg arr_leg ON rp1.legID = arr_leg.legID
WHERE
    f.airplane_status = 'in_flight'
GROUP BY
    dep_leg.departure, arr_leg.arrival;


-- [17] people_on_the_ground()
-- -----------------------------------------------------------------------------
/* This view describes where people who are currently on the ground are located. */
-- -----------------------------------------------------------------------------
create or replace view people_on_the_ground (departing_from, airport, airport_name,
	city, state, country, num_pilots, num_passengers, joint_pilots_passengers, person_list) as
SELECT 
    ap.airportID AS departing_from,
    loc.locationID AS airport,
    ap.airport_name,
    ap.city,
    ap.state,
    ap.country,
    SUM(CASE WHEN pil.taxID IS NOT NULL THEN 1 ELSE 0 END) AS num_pilots,
    SUM(CASE WHEN pass.personID IS NOT NULL THEN 1 ELSE 0 END) AS num_passengers,
    COUNT(p.personID) AS joint_pilots_passengers,
    GROUP_CONCAT(DISTINCT p.personID ORDER BY p.personID ASC SEPARATOR ', ') AS person_list
FROM 
    airport ap
    JOIN location loc ON ap.locationID = loc.locationID
    LEFT JOIN person p ON loc.locationID = p.locationID
    LEFT JOIN pilot pil ON pil.personID = p.personID AND pil.commanding_flight IS NULL
    LEFT JOIN passenger pass ON pass.personID = p.personID
GROUP BY 
    ap.airportID
HAVING
    COUNT(p.personID) > 0;


-- [18] route_summary()
-- -----------------------------------------------------------------------------
/* This view describes how the routes are being utilized by different flights. */
-- -----------------------------------------------------------------------------
create or replace view route_summary (route, num_legs, leg_sequence, route_length,
	num_flights, flight_list, airport_sequence) as
SELECT
    r.routeID AS 'route',
    COUNT(DISTINCT rp.legID) AS 'num_legs',
	GROUP_CONCAT(DISTINCT l.legID ORDER BY rp.sequence ASC SEPARATOR ', ') AS 'leg_sequence',
    (SELECT SUM(distance) FROM leg l2 WHERE l2.legID IN (SELECT legID FROM route_path rp2 WHERE rp2.routeID = r.routeID)) AS 'route_length',
    COUNT(DISTINCT f.flightID) AS 'num_flights',
    GROUP_CONCAT(DISTINCT f.flightID ORDER BY f.flightID ASC SEPARATOR ', ') AS 'flight_list',
    (SELECT 
        GROUP_CONCAT(CONCAT(a_dep.airportID, '->', a_arr.airportID) ORDER BY rp_inner.sequence ASC SEPARATOR ', ') 
     FROM 
        route_path rp_inner 
        JOIN leg l_inner ON rp_inner.legID = l_inner.legID 
        JOIN airport a_dep ON l_inner.departure = a_dep.airportID 
        JOIN airport a_arr ON l_inner.arrival = a_arr.airportID
	WHERE 
        rp_inner.routeID = r.routeID
	GROUP BY 
        rp_inner.routeID) AS 'airport_sequence'
FROM
    route r
JOIN route_path rp ON r.routeID = rp.routeID
JOIN leg l ON rp.legID = l.legID
LEFT JOIN flight f ON r.routeID = f.routeID
JOIN airport a_dep ON l.departure = a_dep.airportID
JOIN airport a_arr ON l.arrival = a_arr.airportID
GROUP BY
    r.routeID;

-- [19] alternative_airports()
-- -----------------------------------------------------------------------------
/* This view displays airports that share the same city and state. */
-- -----------------------------------------------------------------------------
create or replace view alternative_airports (city, state, country, num_airports,
	airport_code_list, airport_name_list) as
SELECT
    city,
    state,
    country,
    COUNT(*) AS num_airports,
    GROUP_CONCAT(airportID) AS airport_code_list,
    GROUP_CONCAT(airport_name) AS airport_name_list
FROM (
    SELECT
        city,
        state,
        country,
        airportID,
        airport_name
    FROM
        airport
) AS subquery
GROUP BY
    city, state, country
HAVING 
    COUNT(*) > 1;