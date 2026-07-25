-- =====================================================================
--  BIKE RENTAL DEMO -- GROUP BY
--  Run bike_rental_schema.sql first, then explore these by section.
--  Each block is a stand-alone SELECT; run them one at a time.
--
--  Key idea: GROUP BY collapses rows that share the grouped values into a
--  single row, and aggregate functions (count, sum, avg, min, max) summarise
--  each group. When WHERE is added, rows are filtered FIRST and only the
--  survivors are grouped. (To filter on the aggregated result instead, you
--  would use HAVING -- a separate topic, not shown here.)
-- =====================================================================


-- #####################################################################
-- PART 1 -- GROUP BY alone  (4 examples)
-- #####################################################################

-- G1. The simplest form: one count per group.
--     How many bikes exist of each type?
SELECT bike_type,
       count(*) AS num_bikes
FROM mobility.bikes
GROUP BY bike_type
ORDER BY num_bikes DESC;

-- G2. Several aggregates over the same group.
--     Fleet economics per bike type.
SELECT bike_type,
       count(*)                     AS units,
       round(avg(purchase_price),2) AS avg_price,
       min(purchase_price)          AS cheapest,
       max(purchase_price)          AS priciest,
       round(sum(purchase_price),2) AS fleet_value
FROM mobility.bikes
GROUP BY bike_type
ORDER BY fleet_value DESC;

-- G3. Group by an EXPRESSION, not just a column.
--     date_trunc buckets every trip into its calendar month.
SELECT date_trunc('month', started_at)::date AS month,
       count(*) AS rides
FROM mobility.rentals
GROUP BY date_trunc('month', started_at)
ORDER BY month;

SELECT extract(month from started_at) AS month,
        extract(year from started_at) AS year,
       count(*) AS rides
FROM mobility.rentals
GROUP BY extract(month from started_at), extract(year from started_at)
ORDER BY year,month;

-- G4. Group by MULTIPLE columns.
--     Each distinct (congestion_level, incident_reported) pair is one group.
SELECT congestion_level,
       incident_reported,
       count(*)                              AS readings,
       round(avg(avg_speed_kmh)::numeric, 1) AS avg_speed
FROM mobility.traffic_indicators
GROUP BY congestion_level, incident_reported
ORDER BY congestion_level, incident_reported;


-- #####################################################################
-- PART 2 -- GROUP BY with WHERE  (4 examples)
--            WHERE runs BEFORE grouping: it decides which rows are eligible.
-- #####################################################################

-- G5. Filter out rows first, then aggregate.
--     Only COMPLETED rentals (ongoing trips have NULL cost) contribute to
--     revenue figures.
SELECT payment_method,
       count(*)            AS trips,
       round(sum(cost), 2) AS revenue,
       round(avg(cost), 2) AS avg_ticket
FROM mobility.rentals
WHERE ended_at IS NOT NULL          -- exclude ongoing trips before grouping
GROUP BY payment_method
ORDER BY revenue DESC;

-- G6. WHERE on a timestamp range, then group.
--     Weather profile during the mid-year (monsoon-ish) window only.
SELECT weather_condition,
       count(*)                    AS readings,
       round(avg(temperature_c),1) AS avg_temp,
       max(precipitation_mm)       AS max_rain_mm
FROM mobility.climate_readings
WHERE recorded_at >= timestamptz '2025-06-01'
  AND recorded_at <  timestamptz '2025-09-01'
GROUP BY weather_condition
ORDER BY readings DESC;

-- G7. WHERE on a boolean, then group by an enum.
--     Utilisation of bikes that are currently available for hire.
SELECT bike_type,
       count(*)                                 AS available_units,
       round(avg(total_distance_km)::numeric,1) AS avg_km_ridden
FROM mobility.bikes
WHERE is_available                   -- boolean filter applied before grouping
GROUP BY bike_type
ORDER BY available_units DESC;

-- G8. Multiple WHERE conditions (+ a join), then group.
--     Rush-hour, paid, completed trips summarised by the START neighborhood.
SELECT s.neighborhood,
       count(*)             AS rush_paid_rides,
       round(sum(r.cost),2) AS revenue,
       round(avg(r.distance_km),2) AS avg_distance_km
FROM mobility.rentals r
JOIN mobility.stations s ON s.station_id = r.start_station_id
WHERE r.during_rush_hour
  AND r.is_paid
  AND r.cost IS NOT NULL
GROUP BY s.neighborhood
ORDER BY revenue DESC;
