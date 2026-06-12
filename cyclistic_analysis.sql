--Create the initial raw data table structure
CREATE TABLE cyclistic_trips (
    ride_id VARCHAR(255) PRIMARY KEY,
    rideable_type VARCHAR(50),
    started_at TIMESTAMP,
    ended_at TIMESTAMP,
    start_station_name VARCHAR(255),
    start_station_id VARCHAR(255),
    end_station_name VARCHAR(255),
    end_station_id VARCHAR(255),
    start_lat DECIMAL(10, 8),
    start_lng DECIMAL(10, 8),
    end_lat DECIMAL(10, 8),
    end_lng DECIMAL(10, 8),
    member_casual VARCHAR(50)
);


--Drop primary key constraint to allow staging and manipulation
ALTER TABLE cyclistic_trips DROP CONSTRAINT cyclistic_trips_pkey;

--Check total row count of the raw imported dataset
SELECT COUNT(*) FROM cyclistic_trips;


--Create a new table and remove duplicate rows based on unique ride_id
CREATE TABLE cleaned_cyclistic_trips AS
SELECT DISTINCT ON (ride_id) *
FROM cyclistic_trips
ORDER BY ride_id, started_at;


--Add primary key constraint to the new cleaned table for data integrity
ALTER TABLE cleaned_cyclistic_trips ADD PRIMARY KEY (ride_id); 

--Check row count after removing duplicate ride_ids
SELECT COUNT(*) FROM cleaned_cyclistic_trips;


--Drop the temporary raw data table to free up database storage
DROP TABLE cyclistic_trips;


--Add new colummn in table for trip duration and weekday analysis
ALTER TABLE cleaned_cyclistic_trips 
ADD COLUMN ride_length_minutes DECIMAL(10,2),
ADD COLUMN day_of_week INT;

--Populate the new columns with calculated data
UPDATE cleaned_cyclistic_trips
SET 
    ride_length_minutes = EXTRACT(EPOCH FROM (ended_at - started_at))/60,
    day_of_week = EXTRACT(DOW FROM started_at) + 1;

--Remove bad data and outliers (less than 1 min or more than 24 hours)
DELETE FROM cleaned_cyclistic_trips
WHERE 
    ended_at <= started_at 
    OR ride_length_minutes <= 1 
    OR ride_length_minutes >= 1440;


--Check total row count after all cleaning steps
SELECT COUNT(*) FROM cleaned_cyclistic_trips;	
--View all columns and the first 10 rows of the cleaned table
SELECT * FROM cleaned_cyclistic_trips 
LIMIT 10;

--Calculate total rides and average duration for members vs casual riders
SELECT 
    member_casual,
    COUNT(ride_id) AS total_rides,
    ROUND(AVG(ride_length_minutes), 2) AS avg_ride_duration_minutes
FROM cleaned_cyclistic_trips
GROUP BY member_casual;


--Count total rides and average duration grouped by day of the week
SELECT 
    member_casual,
    day_of_week,
    COUNT(ride_id) AS total_rides,
    ROUND(AVG(ride_length_minutes), 2) AS avg_ride_duration_minutes
FROM cleaned_cyclistic_trips
GROUP BY member_casual, day_of_week
ORDER BY member_casual, day_of_week;


--Count total rides for each bike type based on rider group
SELECT 
    member_casual,
    rideable_type,
    COUNT(ride_id) AS total_rides,
    ROUND(AVG(ride_length_minutes), 2) AS avg_ride_duration_minutes
FROM cleaned_cyclistic_trips
GROUP BY member_casual, rideable_type
ORDER BY member_casual, total_rides DESC;

--Analyze monthly trends (understand usage differences between members and casual riders across different months.)
SELECT 
    member_casual,
    EXTRACT(MONTH FROM started_at) AS month,
    COUNT(ride_id) AS total_rides
FROM cleaned_cyclistic_trips
GROUP BY member_casual, month
ORDER BY month;


