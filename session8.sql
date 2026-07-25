SELECT count(*)                        AS total_bikes,
       round(avg(purchase_price), 2)   AS avg_price,
       min(weight_kg)                  AS lightest_kg,
       max(total_distance_km)          AS most_travelled_km
FROM mobility.bikes;

SELECT rental_id,
       started_at,
       extract(year  FROM started_at)  AS yr,
       extract(month FROM started_at)  AS mon,
       extract(hour  FROM started_at)  AS hr,
       extract(dow   FROM started_at)  AS day_of_week   -- 0=Sun
FROM mobility.rentals
LIMIT 10;

-- W1. Comparison operators combined with AND / OR (mind the parentheses:
--     AND binds tighter than OR, so group the OR explicitly).
SELECT name, neighborhood, capacity, is_active
FROM mobility.stations
WHERE capacity > 25
  AND (neighborhood = 'Koramangala' OR neighborhood = 'Whitefield')
  AND is_active
ORDER BY capacity DESC;

-- W2. IN / NOT IN -- match against a list of values.
SELECT bike_id, model, bike_type, is_available
FROM mobility.bikes
WHERE bike_type IN ('electric', 'cargo')      -- try NOT IN
ORDER BY bike_type, bike_id
LIMIT 20;

-- W3. BETWEEN -- inclusive range test on a numeric AND a timestamp column.
SELECT rental_id, started_at, cost
FROM mobility.rentals
WHERE cost BETWEEN 5 AND 15
  AND started_at BETWEEN timestamptz '2025-06-01' AND timestamptz '2025-06-30'
ORDER BY cost DESC
LIMIT 20;

-- W4. LIKE / ILIKE -- pattern matching with wildcards
--     %  = any sequence of characters,  _ = exactly one character.
--     ILIKE is the case-insensitive form.
SELECT full_name, email, membership_tier
FROM mobility.riders
WHERE email ILIKE '%@example.org'             -- the hand-crafted showcase riders
   OR full_name LIKE 'A%'                      -- names starting with capital A
ORDER BY full_name
LIMIT 20;

-- W5. IS NULL / IS NOT NULL 
SELECT rental_id, rider_id, started_at, ended_at
FROM mobility.rentals
WHERE ended_at IS NULL                         -- trips still in progress
ORDER BY started_at
LIMIT 20;


-- J1. INNER JOIN
--     Returns only rows that have a match on BOTH sides.
--     Here: every rental paired with its rider and bike.
SELECT r.rental_id,
       ri.full_name,
       b.model,
       b.bike_type,
       r.cost
FROM mobility.rentals r
INNER JOIN mobility.riders ri ON ri.rider_id = r.rider_id
INNER JOIN mobility.bikes  b  ON b.bike_id  = r.bike_id
ORDER BY r.cost DESC NULLS LAST
LIMIT 15;

-- J2. LEFT (OUTER) JOIN
--     Keeps ALL rows from the LEFT table; unmatched right side becomes NULL.
--     Here: every station, even ones with no bikes stationed there (count 0).
SELECT s.station_id,
       s.name,
       count(b.bike_id) AS bikes_stationed     -- count() ignores the NULLs -> 0
FROM mobility.stations s
LEFT JOIN mobility.bikes b ON b.home_station_id = s.station_id
GROUP BY s.station_id, s.name
ORDER BY bikes_stationed ASC, s.station_id     -- stations with 0 bikes surface first
LIMIT 15;

-- J3. RIGHT (OUTER) JOIN
--     Mirror image of LEFT: keeps ALL rows from the RIGHT table.
--     Same result as J2, but driven from the bikes table instead.
SELECT s.station_id,
       s.name,
       count(b.bike_id) AS bikes_stationed
FROM mobility.bikes b
RIGHT JOIN mobility.stations s ON b.home_station_id = s.station_id
GROUP BY s.station_id, s.name
ORDER BY bikes_stationed ASC, s.station_id
LIMIT 15;

-- J4. FULL (OUTER) JOIN
--     Keeps unmatched rows from BOTH sides (NULLs where there is no match).
--     Here: compare how often each station is used as a trip START vs END.
--     A station may appear only as a start, only as an end, or as both.
SELECT COALESCE(st.sid, en.eid) AS station_id,
       st.starts                AS times_as_start,
       en.ends                  AS times_as_end
FROM (
    SELECT start_station_id AS sid, count(*) AS starts
    FROM mobility.rentals
    GROUP BY start_station_id
) st
FULL OUTER JOIN (
    SELECT end_station_id AS eid, count(*) AS ends
    FROM mobility.rentals
    WHERE end_station_id IS NOT NULL
    GROUP BY end_station_id
) en ON st.sid = en.eid
-- Uncomment to see ONLY the non-overlapping stations (FULL JOIN's whole point):
-- WHERE st.sid IS NULL OR en.eid IS NULL
ORDER BY station_id
LIMIT 25;

-- J5. CROSS JOIN
--     Cartesian product: every row on the left paired with every row on the
--     right (no ON clause). Great for building "all combinations" grids.
--     Here: a planning grid of the 5 largest stations x every bike type.
SELECT s.name AS station,
       bt.bike_type
FROM (SELECT name FROM mobility.stations ORDER BY capacity DESC LIMIT 5) s
CROSS JOIN (SELECT unnest(enum_range(NULL::mobility.bike_type)) AS bike_type) bt
ORDER BY station, bike_type;

-- J6. SELF JOIN
--     A table joined to itself (via two aliases).
--     Here: pairs of different stations that sit in the same neighborhood.
--     a.station_id < b.station_id avoids self-pairs and mirror duplicates.
SELECT a.neighborhood,
       a.name AS station_a,
       b.name AS station_b
FROM mobility.stations a
JOIN mobility.stations b
      ON a.neighborhood = b.neighborhood
     AND a.station_id  < b.station_id
ORDER BY a.neighborhood, station_a
LIMIT 20;