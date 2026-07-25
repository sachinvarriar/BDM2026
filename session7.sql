SELECT count(*) from mobility.bikes;

SELECT * 
FROM mobility.bikes 
limit 5;

SELECT count(*)
from mobility.riders;

SELECT * FROM mobility.riders;
limit 5

SELECT count(*) from mobility.climate_readings;

SELECT * FROM mobility.climate_readings limit 15;

SELECT * FROM mobility.stations limit 20;

SELECT * FROM mobility.rentals limit 5;

SELECT count(distinct station_code) from mobility.stations;

SELECT count(distinct neighborhood) from mobility.stations;

SELECT distinct bike_type from mobility.bikes;

SELECT distinct model from mobility.bikes;

SELECT SUM(total_distance_km) from mobility.bikes

SELECT AVG(total_distance_km) from mobility.bikes

SELECT MIN(total_distance_km), MAX(total_distance_km) from mobility.bikes

