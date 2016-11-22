DROP DATABASE IF EXISTS gtfs;
-- CREATE DATABASE IF NOT EXISTS gtfs;
CREATE DATABASE gtfs
    DEFAULT CHARACTER SET utf8
    DEFAULT COLLATE utf8_general_ci;

USE gtfs

DROP TABLE IF EXISTS city;
CREATE TABLE `city` (
    city_id int AUTO_INCREMENT PRIMARY KEY,
    city_name VARCHAR(255),
    insertion_date DATE
);

DROP TABLE IF EXISTS agency;
-- agency_id,agency_name,agency_url,agency_timezone,agency_phone,agency_lang
CREATE TABLE `agency` (
    city_id int NOT NULL,
    agency_id VARCHAR(255) NOT NULL,
    agency_name VARCHAR(255),
    agency_url VARCHAR(255),
    agency_timezone VARCHAR(50),
    agency_lang VARCHAR(50),
    agency_phone VARCHAR(255),
    agency_fare_url VARCHAR(255),
    CONSTRAINT agency_pk PRIMARY KEY (city_id,agency_id)
);

DROP TABLE IF EXISTS stops;
-- stop_id,stop_code,stop_name,stop_desc,stop_lat,stop_lon,zone_id,stop_url,location_type,parent_station,stop_timezone,wheelchair_boarding
CREATE TABLE `stops` (
    stop_id VARCHAR(255) NOT NULL PRIMARY KEY,
	stop_code VARCHAR(255),
	stop_name VARCHAR(255),
	stop_desc VARCHAR(255),
	stop_lat DECIMAL(8,6),
	stop_lon DECIMAL(8,6),
	zone_id VARCHAR(255),
	stop_url VARCHAR(255),
	location_type INT(2),
	parent_station VARCHAR(255),
	stop_timezone VARCHAR(50),
	wheelchair_boarding INT(2)
);

DROP TABLE IF EXISTS routes;
-- route_id,agency_id,route_short_name,route_long_name,route_desc,route_type,route_url,route_color,route_text_color
CREATE TABLE `routes` (
    city_id int NOT NULL,
    route_id VARCHAR(255) NOT NULL,
	agency_id VARCHAR(255),
	route_short_name VARCHAR(50),
	route_long_name VARCHAR(255),
	route_desc VARCHAR(255),
	route_type INT(2),
	route_url VARCHAR(255),
	route_color VARCHAR(20),
	route_text_color VARCHAR(20),
    CONSTRAINT routes_pk PRIMARY KEY (city_id,route_id),
	FOREIGN KEY (city_id,agency_id) REFERENCES agency(city_id,agency_id),
	KEY `agency_key` (city_id,agency_id),
	KEY `route_type` (route_type)
);

DROP TABLE IF EXISTS calendar;
-- service_id,monday,tuesday,wednesday,thursday,friday,saturday,sunday,start_date,end_date
CREATE TABLE `calendar` (
    city_id int NOT NULL,
    service_id VARCHAR(255) NOT NULL,
	monday TINYINT(1),
	tuesday TINYINT(1),
	wednesday TINYINT(1),
	thursday TINYINT(1),
	friday TINYINT(1),
	saturday TINYINT(1),
	sunday TINYINT(1),
	start_date DATE,	
	end_date DATE,
    CONSTRAINT calendar_pk PRIMARY KEY (city_id,service_id)
);

DROP TABLE IF EXISTS shapes;
-- shape_id,shape_pt_lat,shape_pt_lon,shape_pt_sequence
CREATE TABLE `shapes` (
	shape_id VARCHAR(255),
	shape_pt_lat DECIMAL(10,6),
	shape_pt_lon DECIMAL(10,6),
	shape_pt_sequence VARCHAR(255),
	shape_dist_traveled VARCHAR(8)
);

DROP TABLE IF EXISTS trips;
-- trip_id,route_id,service_id,trip_headsign,trip_short_name,direction_id,shape_id
CREATE TABLE `trips` (
    city_id int NOT NULL,
	trip_id VARCHAR(255) NOT NULL PRIMARY KEY,	
	route_id VARCHAR(255),
	service_id VARCHAR(255),
	trip_headsign VARCHAR(255),
	trip_short_name VARCHAR(255),
	direction_id TINYINT(1),
	block_id VARCHAR(255),
	shape_id VARCHAR(255),
	wheelchair_accessible TINYINT(1),
	FOREIGN KEY (city_id,route_id) REFERENCES routes(city_id,route_id),
	FOREIGN KEY (city_id,service_id) REFERENCES calendar(city_id,service_id),
	/*FOREIGN KEY (shape_id) REFERENCES shapes(shape_id),*/
	KEY `route_key` (city_id,route_id),
	KEY `service_id` (city_id,service_id),
	KEY `direction_id` (direction_id)
);

DROP TABLE IF EXISTS stop_times;
-- trip_id,arrival_time,stop_id,stop_sequence,departure_time,stop_headsign,pickup_type,drop_off_type,shape_dist_traveled
CREATE TABLE `stop_times` (
    trip_id VARCHAR(255),
	arrival_time TIME,
	departure_time TIME,
	stop_id VARCHAR(255),
	stop_sequence VARCHAR(255),
	stop_headsign VARCHAR(8),
	pickup_type INT(2),
	drop_off_type INT(2),
	shape_dist_traveled VARCHAR(8),
	FOREIGN KEY (trip_id) REFERENCES trips(trip_id),
	FOREIGN KEY (stop_id) REFERENCES stops(stop_id),
	KEY `trip_id` (trip_id),
	KEY `stop_id` (stop_id),
	KEY `stop_sequence` (stop_sequence),
	KEY `pickup_type` (pickup_type),
	KEY `drop_off_type` (drop_off_type)
);


DROP TABLE IF EXISTS calendar_dates;
-- service_id,date,exception_type
CREATE TABLE `calendar_dates` (
    city_id int NOT NULL,
    service_id VARCHAR(255),
    `date` VARCHAR(8),
    exception_type INT(2),
    FOREIGN KEY (city_id,service_id) REFERENCES calendar(city_id,service_id),
    KEY `exception_type` (exception_type)    
);

DROP TABLE IF EXISTS fare_attributes;
-- fare_id, price, currency_type, payment_method, transfers, transfer_duration
CREATE TABLE `fare_attributes` (
    fare_id VARCHAR(255) NOT NULL PRIMARY KEY,
    price FLOAT(5,2),
    currency_type VARCHAR(10),
	payment_method 	TINYINT(1),
	transfers TINYINT(1),
	transfer_duration INT(10)
);

DROP TABLE IF EXISTS fare_rules;
-- fare_id, route_id, origin_id, destination_id, contains_id
CREATE TABLE `fare_rules` (
    city_id int NOT NULL,
	fare_id VARCHAR(255),
	route_id VARCHAR(255),
	origin_id VARCHAR(255),
	destination_id VARCHAR(255),
	contains_id VARCHAR(255),
	FOREIGN KEY (city_id,route_id) REFERENCES routes(city_id,route_id),
	FOREIGN KEY (fare_id) REFERENCES fare_attributes(fare_id)
);

DROP TABLE IF EXISTS frequencies;
-- trip_id,start_time,end_time,headway_secs
CREATE TABLE `frequencies` (
	trip_id VARCHAR(255),
	start_time TIME,
	end_time TIME,
	headway_secs INT(10),
	exact_times TINYINT(1),
	FOREIGN KEY (trip_id) REFERENCES trips(trip_id)
);

DROP TABLE IF EXISTS transfers;
-- from_stp_id,to_stop_id,transfer_type,min_transfer_time
CREATE TABLE `transfers` (
	from_stop_id VARCHAR(255),
	to_stop_id VARCHAR(255),
	transfer_type TINYINT(2),
	min_transfer_time INT(10),
	FOREIGN KEY (from_stop_id) REFERENCES stops(stop_id),
	FOREIGN KEY (to_stop_id) REFERENCES stops(stop_id),
	KEY `transfer_type` (transfer_type)  
);

DROP TABLE IF EXISTS feed_info;
-- feed_publisher_name,feed_publisher_url,feed_lang,feed_start_date,feed_end_date,feed_version
CREATE TABLE `feed_info` (
	feed_publisher_name VARCHAR(255),
	feed_publisher_url VARCHAR(255),
	feed_lang VARCHAR(255),
	feed_start_date DATE,
	feed_end_date DATE,
	feed_version VARCHAR(255) 
);




