-- CS4400: Introduction to Database Systems: Monday, September 11, 2023
-- Simple Airline Management System Course Project Database TEMPLATE (v0)

/* This is a standard preamble for most of our scripts.  The intent is to establish
a consistent environment for the database behavior. */
set global transaction isolation level serializable;
set global SQL_MODE = 'ANSI,TRADITIONAL';
set names utf8mb4;
set SQL_SAFE_UPDATES = 0;

set @thisDatabase = 'flight_tracking';
drop database if exists flight_tracking;
create database if not exists flight_tracking;
use flight_tracking;

-- Please enter your team number and names here
-- Team 75
-- Members: Hyunsoo Yang, Jongwook Chung, Seohee Yoon

-- Define the database structures
/* You must enter your tables definitions, along with your primary, unique and foreign key
declarations, and data insertion statements here.  You may sequence them in any order that
works for you.  When executed, your statements must create a functional database that contains
all of the data, and supports as many of the constraints as reasonably possible. */

-- route = (routeID)
DROP TABLE IF EXISTS route;
CREATE TABLE route (
	routeID char(50) NOT NULL,
	PRIMARY KEY (routeID)
) ENGINE=InnoDB;

-- routeContains(routeID[fk1], legID[fk2], sequence)
-- Fk1: routeID -> route.routeID, routeID is non-null
-- Fk2: legID -> leg.legID
DROP TABLE IF EXISTS routeContains;
CREATE TABLE routeContains (
	routeID char(50) NOT NULL,
	legID char(50) NOT NULL,
	sequence integer NOT NULL,
	CONSTRAINT sequence_valid CHECK (sequence > 0),
	PRIMARY KEY (routeID, legID, sequence)
) ENGINE=InnoDB;

-- flight(flightID, cost, flightFollows[fk3])
-- Fk3: flightFollows -> route.routeID, flightFollows is non-null
DROP TABLE IF EXISTS flight;
CREATE TABLE flight (
	flightID char(50) NOT NULL,
	cost char(100) NOT NULL,
	flightFollows char(50) NOT NULL,
	PRIMARY KEY (flightID)
)  ENGINE=INNODB;

-- leg(legID, distance, departs[fk4], arrives[fk5])
-- Fk4: departs -> airport.airportID, departs is non-null
-- Fk5: arrives -> airport.airportID, arrives is non-null
DROP TABLE IF EXISTS leg;
CREATE TABLE leg (
	legID char(50) NOT NULL,
	distance integer DEFAULT NULL,
	departs char(50) NOT NULL,
	arrives char(50) NOT NULL,
	PRIMARY KEY (legID),
	CONSTRAINT ‘distance_valid’ CHECK (distance > 0)
) ENGINE=InnoDB;

-- airport(airportID, airportName, city, state, country, locID[fk6])
-- Fk6: locID -> location.locID
DROP TABLE IF EXISTS airport;
CREATE TABLE airport (
	airportID char(3) NOT NULL,
	airportName char(100) NOT NULL,
	city char(100) NOT NULL,
	state char(100) NOT NULL,
	country char(3) NOT NULL,
	locID char(50) DEFAULT NULL,
	PRIMARY KEY (airportID)
) ENGINE=InnoDB;

-- airline(airlineID, revenue)
DROP TABLE IF EXISTS airline;
CREATE TABLE airline (
	airlineID char(50) NOT NULL,
	revenue integer NOT NULL,
	CONSTRAINT revenue_valid CHECK (revenue > 0),
	PRIMARY KEY (airlineID)
) ENGINE=InnoDB;

-- airplane(airlineID[fk7], tail_num, seat_capacity, speed, locID[fk8])
-- Fk7: airlineID -> Airline.airlineID
-- Fk8: locID -> location.locID
DROP TABLE IF EXISTS airplane;
CREATE TABLE airplane (
	airlineID char(50) NOT NULL,
	tail_num char(50) NOT NULL,
	seat_capacity integer DEFAULT NULL,
	CONSTRAINT seat_capacity_valid CHECK (seat_capacity > 0),
	speed integer DEFAULT NULL,
	CONSTRAINT speed_valid CHECK (speed > 0),
	locID char(50) DEFAULT NULL,
	PRIMARY KEY (airlineID, tail_num)
) ENGINE=InnoDB;

-- supports(flightID[fk9], airplaneID, tail_num[fk10], suppProgress, suppStatus, next_time
-- Fk9: flightID -> flight.flightID
-- Fk10: airplaneID -> airplane.airlineID, tail_num -> airplane.tail_num
DROP TABLE IF EXISTS supports;
CREATE TABLE supports (
	flightID char(50) NOT NULL,
	airplaneID char(50) NOT NULL,
	tail_num char(100) NOT NULL,
	suppProgress integer NOT NULL,
	CONSTRAINT suppProgress_valid CHECK (suppProgress >= 0),
	suppStatus char(100) NOT NULL,
	next_time time NOT NULL,
	PRIMARY KEY (flightID, airplaneID, tail_num)
) ENGINE=InnoDB;

-- Prop(airplaneID, tail_num[fk11], props, skids)
-- Fk11: airplaneID, tail_num -> airplane.airlineID, airplane.tail_num
DROP TABLE IF EXISTS prop;
CREATE TABLE prop (
	airplaneID char(50) NOT NULL,
	tail_num char(50) NOT NULL,
	props integer NOT NULL,
	skids boolean NOT NULL,
	PRIMARY KEY (airplaneID, tail_num),
	CONSTRAINT ‘props_valid’ CHECK (props > 0)
) ENGINE=InnoDB;

-- Jet(airplaneID, tail_num[fk12], jetEngines)
-- Fk12: airplaneID, tail_num -> airplane.airlineID, airplane.tail_num
DROP TABLE IF EXISTS jet;
CREATE TABLE jet (
	airplaneID char(50) NOT NULL,
	tail_num char(50) NOT NULL,
	jetEngines integer NOT NULL,
	CONSTRAINT ‘jet_valid’ CHECK (jetEngines > 0),
	PRIMARY KEY (airplaneID, tail_num)
 ) ENGINE=InnoDB;

-- Person(personID, firstName, lastName, occupies[fk13])
-- Fk13: occupies -> location.locID, occupies is non-null
DROP TABLE IF EXISTS person;
CREATE TABLE person (
	personID char(50) NOT NULL,
	firstName char(100) NOT NULL,
	lastName char(100) DEFAULT NULL,
	occupies char(50) NOT NULL,
	PRIMARY KEY (personID)
) ENGINE=InnoDB;

-- passenger(personID[fk14], miles, funds, occupies[fk15])
-- Fk14: personID -> Person.personID
-- Fk15: occupies -> Person.occupies, occupies is non-null
DROP TABLE IF EXISTS passenger;
CREATE TABLE passenger (
	personID char(50) NOT NULL,
	miles integer NOT NULL,
	CONSTRAINT ‘miles_nonnegative’ CHECK (miles >= 0),
	funds integer NOT NULL,
	CONSTRAINT ‘funds_nonnegative’ CHECK (funds >= 0),
	occupies char(50) NOT NULL,
	PRIMARY KEY (personID)
) ENGINE=InnoDB;

-- vacation(passengerID[fk16], destination, sequence)
-- Fk16: passengerID -> passenger.personID
DROP TABLE IF EXISTS vacation;
CREATE TABLE vacation (
	passengerID char(50) NOT NULL,
	destination char(3) NOT NULL,
	sequence integer NOT NULL,
	CONSTRAINT ‘sequence_nonzero’ CHECK (sequence > 0),
	PRIMARY KEY (passengerID, destination, sequence)
) ENGINE=InnoDB;

-- pilot(personID[fk17], taxID, experience, occupies[fk18]
-- Fk17: personID -> Person.personID
-- Fk18: occupies -> Person.occupies, occupies is non-null
DROP TABLE IF EXISTS pilot;
CREATE TABLE pilot (
	personID char(50) NOT NULL,
	taxID char(50) NOT NULL,
	experience integer NOT NULL,
	occupies char(50) NOT NULL,
	PRIMARY KEY (personID),
    UNIQUE (taxID),
	CONSTRAINT ‘experience_nonnegative’ CHECK (experience >= 0)
) ENGINE=InnoDB;

-- license(pilotID[fk19], licenseName)
-- Fk19: pliotID -> Person.personID
DROP TABLE IF EXISTS license;
CREATE TABLE license (
	pilotID char(50) NOT NULL,
	licenseName char(50) NOT NULL,
	PRIMARY KEY (pilotID, licenseName)
) ENGINE=InnoDB;

-- location(locID)
DROP TABLE IF EXISTS location;
CREATE TABLE location (
	locID char(50) NOT NULL,
	PRIMARY KEY (locID)
) ENGINE=InnoDB;

ALTER TABLE routeContains ADD CONSTRAINT routeContains_ibfk1 FOREIGN KEY (routeID) REFERENCES route (routeID);
ALTER TABLE routeContains ADD CONSTRAINT routeContains_ibfk2 FOREIGN KEY (legID) REFERENCES leg (legID);

ALTER TABLE flight ADD CONSTRAINT flight_ibfk3 FOREIGN KEY (flightFollows) REFERENCES route (routeID);

ALTER TABLE leg ADD CONSTRAINT leg_ibfk4 FOREIGN KEY (departs) REFERENCES airport (airportID);
ALTER TABLE leg ADD CONSTRAINT leg_ibfk5 FOREIGN KEY (arrives) REFERENCES airport (airportID);

ALTER TABLE airport ADD CONSTRAINT airport_ibfk6 FOREIGN KEY (locID) REFERENCES location (locID);

ALTER TABLE airplane ADD CONSTRAINT airplane_ibfk7 FOREIGN KEY (airlineID) REFERENCES airline (airlineID);
ALTER TABLE airplane ADD CONSTRAINT airplane_ibfk8 FOREIGN KEY (locID) REFERENCES location (locID);

ALTER TABLE supports ADD CONSTRAINT supports_ibfk9 FOREIGN KEY (flightID) REFERENCES flight (flightID);
ALTER TABLE supports ADD CONSTRAINT supports_ibfk10 FOREIGN KEY (airplaneID, tail_num) REFERENCES airplane (airlineID, tail_num);

ALTER TABLE prop ADD CONSTRAINT prop_ibfk11 FOREIGN KEY (airplaneID, tail_num) REFERENCES airplane (airlineID, tail_num);

ALTER TABLE jet ADD CONSTRAINT jet_ibfk12 FOREIGN KEY (airplaneID, tail_num) REFERENCES airplane (airlineID, tail_num);

ALTER TABLE person ADD CONSTRAINT person_ibfk13 FOREIGN KEY (occupies) REFERENCES location (locID);

ALTER TABLE passenger ADD CONSTRAINT passenger_ibfk14 FOREIGN KEY (personID) REFERENCES person (personID);
ALTER TABLE passenger ADD CONSTRAINT passenger_ibfk15 FOREIGN KEY (occupies) REFERENCES location (locID);

ALTER TABLE vacation ADD CONSTRAINT vacation_ibfk16 FOREIGN KEY (passengerID) REFERENCES passenger (personID);

ALTER TABLE pilot ADD CONSTRAINT pilot_ibfk17 FOREIGN KEY (personID) REFERENCES person (personID);
ALTER TABLE pilot ADD CONSTRAINT pilot_ibfk18 FOREIGN KEY (occupies) REFERENCES location (locID);

ALTER TABLE license ADD CONSTRAINT license_ibfk19 FOREIGN KEY (pilotID) REFERENCES pilot (personID);

-- INSERT queries start here
INSERT INTO route VALUES
('americas_hub_exchange'),
('americas_one'),
('americas_three'),
('americas_two'),
('big_europe_loop'),
('euro_north'),
('euro_south'),
('germany_local'),
('pacific_rim_tour'),
('south_euro_loop'),
('texas_local');

INSERT INTO location VALUES
('port_1'),
('port_2'),
('port_3'),
('port_10'),
('port_17'),
('plane_1'),
('plane_5'),
('plane_8'),
('plane_13'),
('plane_20'),
('port_12'),
('port_14'),
('port_15'),
('port_20'),
('port_4'),
('port_16'),
('port_11'),
('port_23'),
('port_7'),
('port_6'),
('port_13'),
('port_21'),
('port_18'),
('port_22'),
('plane_6'),
('plane_18'),
('plane_7');

INSERT INTO airline VALUES
('Delta',53000),
('United',48000),
('British Airways',24000),
('Lufthansa',35000),
('Air_France',29000),
('KLM',29000),
('Ryanair',10000),
('Japan Airlines',9000),
('China Southern Airlines',14000),
('Korean Air Lines',10000),
('American',52000);


INSERT INTO airplane VALUES
('Delta','n106js',4,800,'plane_1'),
('Delta','n110jn',5,800,NULL),
('Delta','n127js',4,600,NULL),
('United','n330ss',4,800,NULL),
('United','n380sd',5,400,'plane_5'),
('British Airways','n616lt',7,600,'plane_6'),
('British Airways','n517ly',4,600,'plane_7'),
('Lufthansa','n620la',4,800,'plane_8'),
('Lufthansa','n401fj',4,300,NULL),
('Lufthansa','n653fk',6,600,NULL),
('Air_France','n118fm',4,400,NULL),
('Air_France','n815pw',3,400,NULL),
('KLM','n161fk',4,600,'plane_13'),
('KLM','n337as',5,400,NULL),
('KLM','n256ap',4,300,NULL),
('Ryanair','n156sq',8,600,NULL),
('Ryanair','n451fi',5,600,NULL),
('Ryanair','n341eb',4,400,'plane_18'),
('Ryanair','n353kz',4,400,NULL),
('Japan Airlines','n305fv',6,400,'plane_20'),
('Japan Airlines','n443wu',4,800,NULL),
('China Southern Airlines','n454gq',3,400,NULL),
('China Southern Airlines','n249yk',4,400,NULL),
('Korean Air Lines','n180co',5,600,NULL),
('American','n448cs',4,400,NULL),
('American','n225sb',8,800,NULL),
('American','n553qn',5,800,NULL);
 
INSERT INTO jet VALUES
('Delta','n106js',2),
('Delta','n110jn',2),
('Delta','n127js',4),
('United','n330ss',2),
('United','n380sd',2),
('British Airways','n616lt',2),
('British Airways','n517ly',2),
('Lufthansa','n620la',4),
('Lufthansa','n653fk',2),
('Air_France','n815pw',2),
('KLM','n161fk',4),
('KLM','n337as',2),
('Ryanair','n156sq',2),
('Ryanair','n451fi',4),
('Japan Airlines','n305fv',2),
('Japan Airlines','n443wu',4),
('Korean Air Lines','n180co',2),
('American','n225sb',2),
('American','n553qn',2);
 
INSERT INTO prop VALUES
('Air_France','n118fm',2,0),
('KLM','n256ap',2,0),
('Ryanair','n341eb',2,1),
('Ryanair','n353kz',2,1),
('China Southern Airlines','n249yk',2,0),
('American','n448cs',2,1);

INSERT INTO airport VALUES
('ATL','Atlanta Hartsfield_Jackson International','Atlanta','Georgia','USA','port_1'),
('DXB','Dubai International','Dubai','Al Garhoud','UAE','port_2'),
('HND','Tokyo International Haneda','Ota City','Tokyo','JPN','port_3'),
('LHR','London Heathrow','London','England','GBR','port_4'),
('IST','Istanbul International','Arnavutkoy','Istanbul ','TUR',NULL),
('DFW','Dallas_Fort Worth International','Dallas','Texas','USA','port_6'),
('CAN','Guangzhou International','Guangzhou','Guangdong','CHN','port_7'),
('DEN','Denver International','Denver','Colorado','USA',NULL),
('LAX','Los Angeles International','Los Angeles','California','USA',NULL),
('ORD','O_Hare International','Chicago','Illinois','USA','port_10'),
('AMS','Amsterdam Schipol International','Amsterdam','Haarlemmermeer','NLD','port_11'),
('CDG','Paris Charles de Gaulle','Roissy_en_France','Paris','FRA','port_12'),
('FRA','Frankfurt International','Frankfurt','Frankfurt_Rhine_Main','DEU','port_13'),
('MAD','Madrid Adolfo Suarez_Barajas','Madrid','Barajas','ESP','port_14'),
('BCN','Barcelona International','Barcelona','Catalonia','ESP','port_15'),
('FCO','Rome Fiumicino','Fiumicino','Lazio','ITA','port_16'),
('LGW','London Gatwick','London','England','GBR','port_17'),
('MUC','Munich International','Munich','Bavaria','DEU','port_18'),
('MDW','Chicago Midway International','Chicago','Illinois','USA',NULL),
('IAH','George Bush Intercontinental','Houston','Texas','USA','port_20'),
('HOU','William P_Hobby International','Houston','Texas','USA','port_21'),
('NRT','Narita International','Narita','Chiba','JPN','port_22'),
('BER','Berlin Brandenburg Willy Brandt International','Berlin','Schonefeld','DEU','port_23');

INSERT INTO leg VALUES
('leg_1 ',400,'AMS','BER'),
('leg_2',3900,'ATL','AMS'),
('leg_3',3700,'ATL','LHR'),
('leg_4',600,'ATL','ORD'),
('leg_5',500,'BCN','CDG'),
('leg_6',300,'BCN','MAD'),
('leg_7',4700,'BER','CAN'),
('leg_8',600,'BER','LGW'),
('leg_9',300,'BER','MUC'),
('leg_10',1600,'CAN','HND'),
('leg_11',500,'CDG','BCN'),
('leg_12',600,'CDG','FCO'),
('leg_13',200,'CDG','LHR'),
('leg_14',400,'CDG','MUC'),
('leg_15',200,'DFW','IAH'),
('leg_16',800,'FCO','MAD'),
('leg_17',300,'FRA','BER'),
('leg_18',100,'HND','NRT'),
('leg_19',300,'HOU','DFW'),
('leg_20',100,'IAH','HOU'),
('leg_21',600,'LGW','BER'),
('leg_22',600,'LHR','BER'),
('leg_23',500,'LHR','MUC'),
('leg_24',300,'MAD','BCN'),
('leg_25',600,'MAD','CDG'),
('leg_26',800,'MAD','FCO'),
('leg_27',300,'MUC','BER'),
('leg_28',400,'MUC','CDG'),
('leg_29',400,'MUC','FCO'),
('leg_30',200,'MUC','FRA'),
('leg_31',3700,'ORD','CDG');

INSERT INTO routeContains VALUES
('americas_one','leg_2',1),
('americas_one','leg_1',2),
('americas_three','leg_31',1),
('americas_three','leg_14',2),
('americas_two','leg_3',1),
('americas_two','leg_22',2),
('big_europe_loop','leg_23',1),
('big_europe_loop','leg_29',2),
('big_europe_loop','leg_16',3),
('big_europe_loop','leg_25',4),
('big_europe_loop','leg_13',5),
('euro_north','leg_16',1),
('euro_north','leg_24',2),
('euro_north','leg_5',3),
('euro_north','leg_14',4),
('euro_north','leg_27',5),
('euro_north','leg_8',6),
('euro_south','leg_21',1),
('euro_south','leg_9',2),
('euro_south','leg_28',3),
('euro_south','leg_11',4),
('euro_south','leg_6',5),
('euro_south','leg_26',6),
('germany_local','leg_9',1),
('germany_local','leg_30',2),
('germany_local','leg_17',3),
('pacific_rim_tour','leg_7',1),
('pacific_rim_tour','leg_10',2),
('pacific_rim_tour','leg_18',3),
('south_euro_loop','leg_16',1),
('south_euro_loop','leg_24',2),
('south_euro_loop','leg_5',3),
('south_euro_loop','leg_12',4),
('texas_local','leg_15',1),
('texas_local','leg_20',2),
('texas_local','leg_19',3);


INSERT INTO flight VALUES
('dl_10',200,'americas_one'),
('un_38',200,'americas_three'),
('ba_61',200,'americas_two'),
('lf_20',300,'euro_north'),
('km_16',400,'euro_south'),
('ba_51',100,'big_europe_loop'),
('ja_35',300,'pacific_rim_tour'),
('ry_34',100,'germany_local');

INSERT INTO supports VALUES
('dl_10','Delta','n106js',1,'in_flight','08:00:00'),
('un_38','United','n380sd',2,'in_flight','14:30:00'),
('ba_61','British Airways','n616lt',0,'on_ground','09:30:00'),
('lf_20','Lufthansa','n620la',3,'in_flight','11:00:00'),
('km_16','KLM','n161fk',6,'in_flight','14:00:00'),
('ba_51','British Airways','n517ly',0,'on_ground','11:30:00'),
('ja_35','Japan Airlines','n305fv',1,'in_flight','09:30:00'),
('ry_34','Ryanair','n341eb',0,'on_ground','15:00:00');

INSERT INTO person VALUES
('p21','Mona','Harrison','plane_1'),
('p22','Arlene','Massey','plane_1'),
('p23','Judith','Patrick','plane_1'),
('p24','Reginald','Rhodes','plane_5'),
('p25','Vincent','Garcia','plane_5'),
('p26','Cheryl','Moore','plane_5'),
('p27','Michael','Rivera','plane_8'),
('p28','Luther','Matthews','plane_8'),
('p29','Moses','Parks','plane_13'),
('p30','Ora','Steele','plane_13'),
('p31','Antonio','Flores','plane_13'),
('p32','Glenn','Ross','plane_13'),
('p33','Irma','Thomas','plane_20'),
('p34','Ann','Maldonado','plane_20'),
('p35','Jeffrey','Cruz','port_12'),
('p36','Sonya','Price','port_12'),
('p37','Tracy','Hale','port_12'),
('p38','Albert','Simmons','port_14'),
('p39','Karen','Terry','port_15'),
('p40','Glen','Kelley','port_20'),
('p41','Brooke','Little','port_3'),
('p42','Daryl','Nguyen','port_4'),
('p43','Judy','Willis','port_14'),
('p44','Marco','Klein','port_15'),
('p45','Angelica','Hampton','port_16'),
('p9','Marlene','Warner','port_3'),
('p5','Jeff','Burton','port_1'),
('p17','Ruby','Burgess','port_10'),
('p2','Roxanne','Byrd','port_1'),
('p4','Kendra','Jacobs','port_1'),
('p10','Lawrence','Morgan','port_3'),
('p3','Tanya','Nguyen','port_1'),
('p6','Randal','Parks','port_1'),
('p8','Bennie','Palmer','port_2'),
('p12','Dan','Ball','port_3'),
('p16','Edna','Brown','port_10'),
('p20','Thomas','Olson','port_17'),
('p13','Bryant','Figueroa','port_3'),
('p14','Dana','Perry','port_3'),
('p7','Sonya','Owens','port_2'),
('p19','Doug','Fowler','port_17'),
('p11','Sandra','Cruz','port_3'),
('p1','Jeanne','Nelson','port_1'),
('p18','Esther','Pittman','port_10'),
('p15','Matt','Hunt','port_10');

INSERT INTO pilot VALUES
('p9','936-44-6941',13,'port_3'),
('p5','933-93-2165',27,'port_1'),
('p17','865-71-6800',36,'port_10'),
('p2','842-88-1257',9,'port_1'),
('p4','776-21-8098',24,'port_1'),
('p10','769-60-1266',15,'port_3'),
('p3','750-24-7616',11,'port_1'),
('p6','707-84-4555',38,'port_1'),
('p8','701-38-2179',12,'port_2'),
('p12','680-92-5329',24,'port_3'),
('p16','598-47-5172',28,'port_10'),
('p20','522-44-3098',28,'port_17'),
('p13','513-40-4168',24,'port_3'),
('p14','454-71-7847',13,'port_3'),
('p7','450-25-5617',13,'port_2'),
('p19','386-39-7881',2,'port_17'),
('p11','369-22-9505',22,'port_3'),
('p1','330-12-6907',31,'port_1'),
('p18','250-86-2784',23,'port_10'),
('p15','153-47-8101',30,'port_10');

INSERT INTO license VALUES
('p9','jets, props, testing'),
('p5','jets'),
('p17','jets, props'),
('p2','jets, props'),
('p4','jets, props'),
('p10','jets'),
('p3','jets'),
('p6','jets, props'),
('p8','props'),
('p12','props'),
('p16','jets'),
('p20','jets'),
('p13','jets'),
('p14','jets'),
('p7','jets'),
('p19','jets'),
('p11','jets, props'),
('p1','jets'),
('p18','jets'),
('p15','jets, props, testing');

INSERT INTO passenger VALUES
('p21',771,700,'plane_1'),
('p22',374,200,'plane_1'),
('p23',414,400,'plane_1'),
('p24',292,500,'plane_5'),
('p25',390,300,'plane_5'),
('p26',302,600,'plane_5'),
('p27',470,400,'plane_8'),
('p28',208,400,'plane_8'),
('p29',292,700,'plane_13'),
('p30',686,500,'plane_13'),
('p31',547,400,'plane_13'),
('p32',257,500,'plane_13'),
('p33',564,600,'plane_20'),
('p34',211,200,'plane_20'),
('p35',233,500,'port_12'),
('p36',293,400,'port_12'),
('p37',552,700,'port_12'),
('p38',812,700,'port_14'),
('p39',541,400,'port_15'),
('p40',441,700,'port_20'),
('p41',875,300,'port_3'),
('p42',691,500,'port_4'),
('p43',572,300,'port_14'),
('p44',572,500,'port_15'),
('p45',663,500,'port_16');

INSERT INTO vacation VALUES
('p21','AMS',1),
('p22','AMS',1),
('p23','BER',1),
('p24','MUC',1),
('p24','CDG',2),
('p25','MUC',1),
('p26','MUC',1),
('p27','BER',1),
('p28','LGW',1),
('p29','FCO',1),
('p29','LHR',2),
('p30','FCO',1),
('p30','MAD',2),
('p31','FCO',1),
('p32','FCO',1),
('p33','CAN',1),
('p34','HND',1),
('p35','LGW',1),
('p36','FCO',1),
('p37','FCO',1),
('p37','LGW',2),
('p37','CDG',3),
('p38','MUC',1),
('p39','MUC',1),
('p40','HND',1);