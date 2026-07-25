-- =====================================================================
--  BIKE RENTAL + CLIMATE/TRAFFIC  -- mock schema for Supabase (PostgreSQL)
-- ---------------------------------------------------------------------
--  Purpose : a teaching/demo database that exercises EVERY common
--            PostgreSQL data type so you can practise SELECT queries.
--
--  Data types covered:
--    serial / bigserial ...... auto-increment integer PKs
--    smallint / int / bigint . integer sizes
--    numeric(p,s) ............ exact decimals (money, ratings)
--    real / double precision . floating point
--    varchar / char / text ... character types
--    boolean ................. true / false
--    date / time ............. calendar date, wall-clock time
--    timestamp / timestamptz . naive vs. timezone-aware instants
--    interval ................ durations
--    uuid .................... universally unique identifiers
--    jsonb ................... schemaless / nested documents
--    text[] / int[] .......... arrays
--    ENUM .................... custom enumerated types
--    inet .................... IP addresses
--    point ................... 2-D geometric point (lng, lat)
--    daterange ............... range types
--    tsvector ................ full-text search (generated column)
--
--  HOW TO RUN: paste into the Supabase SQL Editor and run once.
--  Re-running is safe: it drops and rebuilds the whole schema.
--
--  Tested against PostgreSQL 15 (Supabase default).
-- =====================================================================

-- Fresh start (also resets sequences so IDs start at 1 and stay contiguous)
DROP SCHEMA IF EXISTS mobility CASCADE;
CREATE SCHEMA mobility;

-- gen_random_uuid() is built into Postgres 13+, so no extension needed.

-- ---------------------------------------------------------------------
-- 1. ENUM TYPES
-- ---------------------------------------------------------------------
CREATE TYPE mobility.bike_type       AS ENUM ('standard','electric','cargo','tandem','kids');
CREATE TYPE mobility.membership_tier AS ENUM ('casual','monthly','annual','student','corporate');
CREATE TYPE mobility.payment_method  AS ENUM ('card','wallet','upi','cash','voucher');
CREATE TYPE mobility.congestion_level AS ENUM ('low','moderate','high','severe');
CREATE TYPE mobility.weather_condition AS ENUM ('clear','cloudy','rain','storm','fog','snow','haze');


-- ---------------------------------------------------------------------
-- 2. TABLES
-- ---------------------------------------------------------------------

-- 2.1 STATIONS -- docking stations (dimension table)
CREATE TABLE mobility.stations (
    station_id      serial PRIMARY KEY,                 -- serial (auto int)
    station_code    varchar(12) UNIQUE NOT NULL,        -- varchar
    name            varchar(120) NOT NULL,
    neighborhood    varchar(80),
    zone_code       char(2),                            -- char(n), blank-padded
    location        point,                              -- point (lng, lat)
    latitude        numeric(9,6),                       -- numeric (exact)
    longitude       numeric(9,6),
    capacity        smallint,                           -- smallint
    current_bikes   smallint,
    is_active       boolean DEFAULT true,               -- boolean
    amenities       text[],                             -- array of text
    opened_on       date,                               -- date
    last_inspection timestamp,                          -- timestamp (no tz)
    metadata        jsonb,                              -- jsonb document
    -- generated tsvector for full-text search over name + neighborhood
    search_doc      tsvector GENERATED ALWAYS AS
                    (to_tsvector('english',
                        coalesce(name,'') || ' ' || coalesce(neighborhood,''))) STORED,
    created_at      timestamptz DEFAULT now()           -- timestamptz
);

-- 2.2 BIKES -- the physical fleet (dimension table)
CREATE TABLE mobility.bikes (
    bike_id            serial PRIMARY KEY,
    bike_uuid          uuid DEFAULT gen_random_uuid() UNIQUE,   -- uuid
    home_station_id    int REFERENCES mobility.stations(station_id),
    model              varchar(80),
    bike_type          mobility.bike_type,                      -- enum
    purchase_price     numeric(10,2),                           -- numeric
    weight_kg          real,                                    -- real (float4)
    total_distance_km  double precision,                        -- float8
    battery_level      smallint,               -- 0-100, NULL for non-electric
    gears              smallint,
    is_available       boolean,
    last_serviced_at   timestamptz,
    warranty_until     date,
    tags               text[],                                  -- text array
    specs              jsonb,
    created_at         timestamptz DEFAULT now()
);

-- 2.3 RIDERS -- members / customers (dimension table)
CREATE TABLE mobility.riders (
    rider_id         serial PRIMARY KEY,
    rider_uuid       uuid DEFAULT gen_random_uuid(),
    full_name        varchar(120),
    email            varchar(160) UNIQUE,
    phone            varchar(20),
    date_of_birth    date,
    membership_tier  mobility.membership_tier,                  -- enum
    membership_valid daterange,                                 -- range type
    is_verified      boolean,
    loyalty_points   int,
    avg_rating       numeric(3,2),
    signup_ip        inet,                                      -- inet
    preferred_language char(2),
    preferences      jsonb,
    created_at       timestamptz DEFAULT now()
);

-- 2.4 RENTALS -- trips (large FACT table)
CREATE TABLE mobility.rentals (
    rental_id        bigserial PRIMARY KEY,                     -- bigserial (bigint)
    rider_id         int REFERENCES mobility.riders(rider_id),
    bike_id          int REFERENCES mobility.bikes(bike_id),
    start_station_id int REFERENCES mobility.stations(station_id),
    end_station_id   int REFERENCES mobility.stations(station_id),  -- NULL while ongoing
    started_at       timestamptz,
    ended_at         timestamptz,                               -- NULL while ongoing
    trip_duration    interval,                                  -- interval
    distance_km      numeric(6,2),
    cost             numeric(8,2),
    is_paid          boolean,
    payment_method   mobility.payment_method,                   -- enum
    rating           smallint,                                  -- 1-5, nullable
    during_rush_hour boolean,
    route            jsonb,                                     -- nested jsonb
    created_at       timestamptz DEFAULT now()
);

-- 2.5 CLIMATE_READINGS -- weather / air-quality indicators near stations (fact)
CREATE TABLE mobility.climate_readings (
    reading_id        bigserial PRIMARY KEY,
    station_id        int REFERENCES mobility.stations(station_id),
    reading_date      date,                                     -- date
    reading_time      time,                                     -- time
    recorded_at       timestamptz,
    temperature_c     numeric(4,1),
    feels_like_c      numeric(4,1),
    humidity_pct      smallint,
    wind_speed_kmh    real,
    precipitation_mm  real,
    weather_condition mobility.weather_condition,               -- enum
    air_quality_index smallint,
    is_extreme        boolean,
    sensor_data       jsonb
);

-- 2.6 TRAFFIC_INDICATORS -- road/bike-lane traffic near stations (fact)
CREATE TABLE mobility.traffic_indicators (
    traffic_id              bigserial PRIMARY KEY,
    station_id              int REFERENCES mobility.stations(station_id),
    measured_at             timestamptz,
    congestion_level        mobility.congestion_level,          -- enum
    avg_speed_kmh           real,
    vehicle_count           int,
    bike_lane_occupancy_pct smallint,
    incident_reported       boolean,
    peak_hours              int[],                              -- int array
    details                 jsonb
);


-- ---------------------------------------------------------------------
-- 3. SEED DATA
--    Generated with generate_series() + random() for volume & variety.
--    Parents are inserted before children so foreign keys stay valid.
--    (IDs are contiguous from 1 because we dropped the schema above.)
-- ---------------------------------------------------------------------

-- 3.1 STATIONS  (200 rows) -----------------------------------------------
INSERT INTO mobility.stations
    (station_code, name, neighborhood, zone_code, location, latitude, longitude,
     capacity, current_bikes, is_active, amenities, opened_on, last_inspection, metadata)
SELECT
    'STN-' || lpad(s.g::text, 4, '0'),
    s.hood || ' ' || (ARRAY['Hub','Dock','Point','Stand','Plaza'])[(floor(random()*5)+1)::int],
    s.hood,
    ('Z' || (floor(random()*9)+1)::text)::char(2),
    point(s.lng, s.lat),
    round(s.lat::numeric, 6),
    round(s.lng::numeric, 6),
    s.cap,
    (floor(random() * (s.cap + 1)))::smallint,          -- current_bikes <= capacity
    random() < 0.92,
    -- each amenity included independently -> varied array membership
    ARRAY(SELECT a FROM unnest(ARRAY['pump','repair_stand','shelter',
             'cctv','ev_charging','locker','info_board']) a WHERE random() < 0.5),
    date '2019-01-01' + (floor(random()*2000))::int,
    timestamp '2026-01-01' + (random() * interval '200 days'),
    jsonb_build_object(
        'zone_tier',  (ARRAY['gold','silver','bronze'])[(floor(random()*3)+1)::int],
        'accessible', random() < 0.8,
        'docks',      jsonb_build_object('total', s.cap,
                                         'working', s.cap - (floor(random()*3))::int),
        'operator',   (ARRAY['CityBike','GreenWheels','MetroCycle'])[(floor(random()*3)+1)::int]
    )
    || CASE WHEN random() < 0.35
            THEN jsonb_build_object('sponsor',
                    (ARRAY['Acme','Globex','Initech'])[(floor(random()*3)+1)::int])
            ELSE '{}'::jsonb END
FROM (
    SELECT g,
        (ARRAY['Indiranagar','Koramangala','Whitefield','Jayanagar','HSR Layout',
               'MG Road','Malleshwaram','Yelahanka','BTM Layout','Hebbal',
               'Marathahalli','Banashankari'])[(floor(random()*12)+1)::int] AS hood,
        (10 + floor(random()*31))::smallint AS cap,     -- capacity 10..40
        12.90 + random()*0.25 AS lat,
        77.55 + random()*0.25 AS lng
    FROM generate_series(1, 200) g
) s;

-- 3.2 BIKES  (500 rows) --------------------------------------------------
INSERT INTO mobility.bikes
    (home_station_id, model, bike_type, purchase_price, weight_kg, total_distance_km,
     battery_level, gears, is_available, last_serviced_at, warranty_until, tags, specs)
SELECT
    (floor(random() * (SELECT count(*) FROM mobility.stations)) + 1)::int,
    b.brand || ' ' || b.line || ' ' || (2019 + floor(random()*7))::int,
    b.bt,
    round((250 + random()*2500)::numeric, 2),
    round((9 + random()*22)::numeric, 1)::real,
    round((random()*8000)::numeric, 3)::double precision,
    CASE WHEN b.bt = 'electric' THEN (floor(random()*101))::smallint ELSE NULL END,
    CASE WHEN b.bt IN ('electric','kids') THEN (floor(random()*3)+1)::smallint
         ELSE (floor(random()*21)+1)::smallint END,
    random() < 0.8,
    now() - (random() * interval '180 days'),
    current_date + (floor(random()*900) - 200)::int,    -- some expired, some valid
    ARRAY(SELECT t FROM unnest(ARRAY['new','refurbished','gps','basket',
             'child_seat','premium','needs_service']) t WHERE random() < 0.4),
    jsonb_build_object(
        'frame',      (ARRAY['aluminium','steel','carbon'])[(floor(random()*3)+1)::int],
        'brake',      (ARRAY['disc','rim','hydraulic'])[(floor(random()*3)+1)::int],
        'wheel_inch', (ARRAY[20,24,26,28,29])[(floor(random()*5)+1)::int],
        'colors',     ARRAY(SELECT c FROM unnest(ARRAY['red','blue','black',
                             'green','yellow']) c WHERE random() < 0.5)
    )
    || CASE WHEN b.bt = 'electric'
            THEN jsonb_build_object('battery',
                    jsonb_build_object(
                        'capacity_wh', (ARRAY[250,350,500])[(floor(random()*3)+1)::int],
                        'removable',   random() < 0.6))
            ELSE '{}'::jsonb END
FROM (
    SELECT g,
        (ARRAY['standard','electric','cargo','tandem','kids']::mobility.bike_type[])
            [(floor(random()*5)+1)::int] AS bt,
        (ARRAY['Trek','Giant','Hero','BSA','Firefox','Cannondale'])
            [(floor(random()*6)+1)::int] AS brand,
        (ARRAY['Urban','Trail','Metro','Sprint','Cruise'])
            [(floor(random()*5)+1)::int] AS line
    FROM generate_series(1, 500) g
) b;

-- 3.3 RIDERS  (500 generated rows) --------------------------------------
INSERT INTO mobility.riders
    (full_name, email, phone, date_of_birth, membership_tier, membership_valid,
     is_verified, loyalty_points, avg_rating, signup_ip, preferred_language, preferences)
SELECT
    r.fn || ' ' || r.ln,
    'rider' || g || '@example.com',
    '+91-' || (7000000000 + floor(random()*1000000000))::bigint::text,
    date '1965-01-01' + (floor(random()*16000))::int,   -- born ~1965..2008
    r.tier,
    daterange(r.start_d, r.start_d + (ARRAY[30,90,180,365])[(floor(random()*4)+1)::int]),
    random() < 0.75,
    (floor(random()*5000))::int,
    round((3 + random()*2)::numeric, 2),                 -- avg rating 3.00..5.00
    ((floor(random()*223)+1)::text || '.' || floor(random()*256)::text || '.' ||
     floor(random()*256)::text || '.' || (floor(random()*254)+1)::text)::inet,
    (ARRAY['en','hi','kn','ta','te'])[(floor(random()*5)+1)::int]::char(2),
    jsonb_build_object(
        'notify', jsonb_build_object('email', random() < 0.7,
                                     'sms',   random() < 0.4,
                                     'push',  random() < 0.6),
        'favourite_stations',
            ARRAY(SELECT (floor(random() * (SELECT count(*) FROM mobility.stations)) + 1)::int
                  FROM generate_series(1, (floor(random()*3))::int + 1)),
        'bike_pref',  (ARRAY['standard','electric','any'])[(floor(random()*3)+1)::int],
        'newsletter', random() < 0.5
    )
    || CASE WHEN random() < 0.3
            THEN jsonb_build_object('referral',
                    jsonb_build_object('code', 'REF' || g,
                                       'credits', floor(random()*500)))
            ELSE '{}'::jsonb END
FROM (
    SELECT g,
        (ARRAY['Aarav','Vivaan','Diya','Ananya','Kabir','Isha',
               'Rohan','Meera','Arjun','Sara','Dev','Nisha'])[(floor(random()*12)+1)::int] AS fn,
        (ARRAY['Sharma','Reddy','Iyer','Nair','Gupta',
               'Rao','Khan','Menon','Patel','Bose'])[(floor(random()*10)+1)::int] AS ln,
        (ARRAY['casual','monthly','annual','student','corporate']::mobility.membership_tier[])
            [(floor(random()*5)+1)::int] AS tier,
        date '2024-01-01' + (floor(random()*550))::int AS start_d
    FROM generate_series(1, 500) g
) r;

-- 3.3b RIDERS -- a few hand-crafted "showcase" rows with rich JSONB
--       (memorable emails + nested docs make JSON-path demos easy to read)
INSERT INTO mobility.riders
    (full_name, email, phone, date_of_birth, membership_tier, membership_valid,
     is_verified, loyalty_points, avg_rating, signup_ip, preferred_language, preferences)
VALUES
('Grace Hopper','grace@example.org','+1-202-555-0100','1980-12-09','annual',
 '[2025-01-01,2026-01-01)', true, 4820, 4.95, '10.0.0.7', 'en',
 '{"notify":{"email":true,"sms":true,"push":false},
   "bike_pref":"electric","newsletter":true,
   "favourite_stations":[1,5,12],
   "referral":{"code":"GRACE10","credits":500},
   "achievements":["1000km_club","early_adopter","zero_incidents"],
   "billing":{"plan":"annual","auto_renew":true,"currency":"USD"}}'::jsonb),
('Alan Turing','alan@example.org','+44-20-7946-0102','1982-06-23','corporate',
 '[2025-03-01,2026-03-01)', true, 3110, 4.80, '192.168.10.4', 'en',
 '{"notify":{"email":true,"sms":false,"push":true},
   "bike_pref":"any","newsletter":false,
   "favourite_stations":[3,8],
   "company":{"name":"Bletchley Ltd","seat_count":40,"cost_center":"R&D"},
   "billing":{"plan":"corporate","auto_renew":true,"currency":"GBP"}}'::jsonb),
('Ada Lovelace','ada@example.org','+91-80-2555-0103','1990-12-10','student',
 '[2025-06-01,2025-12-01)', false, 260, 4.20, '172.16.5.9', 'en',
 '{"notify":{"email":true,"sms":true,"push":true},
   "bike_pref":"standard","newsletter":true,
   "favourite_stations":[2],
   "student":{"institute":"IISc","valid_id":true,"discount_pct":25}}'::jsonb),
('Katherine Johnson','katherine@example.org','+1-757-555-0104','1975-08-26','monthly',
 '[2025-07-01,2025-08-01)', true, 980, 4.99, '10.10.10.10', 'en',
 '{"notify":{"email":false,"sms":false,"push":true},
   "bike_pref":"electric","newsletter":false,
   "favourite_stations":[7,9,15,20],
   "referral":{"code":"KJ2025","credits":150}}'::jsonb),
('Ravi Kumar','ravi@example.org','+91-80-2555-0105','2001-02-14','casual',
 '[2025-05-15,2025-06-14)', false, 40, 3.10, '203.0.113.55', 'kn',
 '{"notify":{"email":true},"bike_pref":"any","newsletter":false,
   "favourite_stations":[]}'::jsonb);

-- 3.4 RENTALS  (1500 rows) ----------------------------------------------
INSERT INTO mobility.rentals
    (rider_id, bike_id, start_station_id, end_station_id, started_at, ended_at,
     trip_duration, distance_km, cost, is_paid, payment_method, rating,
     during_rush_hour, route)
SELECT
    (floor(random() * (SELECT count(*) FROM mobility.riders))   + 1)::int,
    (floor(random() * (SELECT count(*) FROM mobility.bikes))    + 1)::int,
    s.start_st,
    CASE WHEN s.ongoing THEN NULL ELSE s.end_st END,
    s.started_at,
    CASE WHEN s.ongoing THEN NULL ELSE s.started_at + make_interval(mins => s.dur) END,
    CASE WHEN s.ongoing THEN NULL ELSE make_interval(mins => s.dur) END,
    CASE WHEN s.ongoing THEN NULL ELSE round((s.dur * 0.18 + random()*2)::numeric, 2) END,
    CASE WHEN s.ongoing THEN NULL ELSE round((1.50 + s.dur * 0.12)::numeric, 2) END,
    CASE WHEN s.ongoing THEN false ELSE random() < 0.95 END,
    (ARRAY['card','wallet','upi','cash','voucher']::mobility.payment_method[])
        [(floor(random()*5)+1)::int],
    CASE WHEN s.ongoing OR random() < 0.3 THEN NULL ELSE (floor(random()*5)+1)::smallint END,
    extract(hour FROM s.started_at) IN (7,8,9,17,18,19),
    jsonb_build_object(
        'start_station', s.start_st,
        'end_station',   CASE WHEN s.ongoing THEN NULL ELSE s.end_st END,
        'waypoints', jsonb_build_array(
            jsonb_build_object('lat', round((12.90 + random()*0.25)::numeric, 5),
                               'lng', round((77.55 + random()*0.25)::numeric, 5)),
            jsonb_build_object('lat', round((12.90 + random()*0.25)::numeric, 5),
                               'lng', round((77.55 + random()*0.25)::numeric, 5))
        ),
        'avg_speed_kmh', round((10 + random()*15)::numeric, 1)
    )
    || CASE WHEN random() < 0.4
            THEN jsonb_build_object('promo_code',
                    (ARRAY['SUMMER10','RIDE5','WELCOME','GOGREEN'])[(floor(random()*4)+1)::int])
            ELSE '{}'::jsonb END
FROM (
    SELECT
        (floor(random() * (SELECT count(*) FROM mobility.stations)) + 1)::int AS start_st,
        (floor(random() * (SELECT count(*) FROM mobility.stations)) + 1)::int AS end_st,
        timestamptz '2025-01-01 00:00:00+05:30' + (random() * interval '540 days') AS started_at,
        (floor(random()*117) + 3)::int AS dur,          -- 3..119 minutes
        random() < 0.05 AS ongoing                      -- ~5% still out on a ride
    FROM generate_series(1, 1500) g
) s;

-- 3.5 CLIMATE_READINGS  (900 rows) --------------------------------------
INSERT INTO mobility.climate_readings
    (station_id, reading_date, reading_time, recorded_at, temperature_c, feels_like_c,
     humidity_pct, wind_speed_kmh, precipitation_mm, weather_condition,
     air_quality_index, is_extreme, sensor_data)
SELECT
    (floor(random() * (SELECT count(*) FROM mobility.stations)) + 1)::int,
    c.recorded_at::date,
    c.recorded_at::time,
    c.recorded_at,
    c.temp,
    round((c.temp + (random()*4 - 2))::numeric, 1),     -- feels-like near temp
    c.hum,
    c.wind,
    c.precip,
    c.wc,
    c.aqi,
    (c.temp >= 38 OR c.precip >= 30 OR c.aqi >= 200 OR c.wind >= 30) AS is_extreme,
    jsonb_build_object(
        'sensor_id',   'SEN-' || lpad((floor(random()*300)+1)::text, 3, '0'),
        'calibrated',  random() < 0.9,
        'battery_pct', floor(random()*100),
        'readings',    jsonb_build_object('temp', c.temp,
                                          'humidity', c.hum,
                                          'pm25', round((random()*150)::numeric, 1))
    )
    || CASE WHEN (c.temp >= 38 OR c.precip >= 30 OR c.aqi >= 200 OR c.wind >= 30)
            THEN jsonb_build_object('alerts',
                    to_jsonb(ARRAY(SELECT a FROM unnest(ARRAY['heat','storm',
                             'poor_air','wind']) a WHERE random() < 0.5)))
            ELSE '{}'::jsonb END
FROM (
    SELECT
        timestamptz '2025-01-01 00:00:00+05:30' + (random() * interval '540 days') AS recorded_at,
        round((18 + random()*22)::numeric, 1)   AS temp,     -- 18.0 .. 40.0 C
        (30 + floor(random()*70))::smallint     AS hum,      -- 30 .. 99 %
        round((random()*35)::numeric, 1)::real  AS wind,     -- 0 .. 35 km/h
        round((random()*40)::numeric, 1)::real  AS precip,   -- 0 .. 40 mm
        (ARRAY['clear','cloudy','rain','storm','fog','snow','haze']::mobility.weather_condition[])
            [(floor(random()*7)+1)::int]        AS wc,
        (floor(random()*300)+10)::smallint      AS aqi       -- 10 .. 309
    FROM generate_series(1, 900) g
) c;

-- 3.6 TRAFFIC_INDICATORS  (900 rows) ------------------------------------
INSERT INTO mobility.traffic_indicators
    (station_id, measured_at, congestion_level, avg_speed_kmh, vehicle_count,
     bike_lane_occupancy_pct, incident_reported, peak_hours, details)
SELECT
    (floor(random() * (SELECT count(*) FROM mobility.stations)) + 1)::int,
    t.measured_at,
    t.cong,
    t.speed,
    t.vcount,
    (floor(random()*101))::smallint,
    t.incident,
    ARRAY(SELECT h FROM unnest(ARRAY[7,8,9,17,18,19,20]) h WHERE random() < 0.5),
    jsonb_build_object(
        'source', (ARRAY['sensor','camera','crowdsourced'])[(floor(random()*3)+1)::int],
        'lanes',  jsonb_build_object('total', (floor(random()*4)+1),
                                     'blocked', floor(random()*2)),
        'weather_linked', random() < 0.5
    )
    || CASE WHEN t.incident
            THEN jsonb_build_object('incident',
                    jsonb_build_object(
                        'type',     (ARRAY['accident','construction','event','breakdown'])
                                        [(floor(random()*4)+1)::int],
                        'severity', (ARRAY['minor','major'])[(floor(random()*2)+1)::int]))
            ELSE '{}'::jsonb END
FROM (
    SELECT
        timestamptz '2025-01-01 00:00:00+05:30' + (random() * interval '540 days') AS measured_at,
        (ARRAY['low','moderate','high','severe']::mobility.congestion_level[])
            [(floor(random()*4)+1)::int]        AS cong,
        round((5 + random()*55)::numeric, 1)::real AS speed,   -- 5 .. 60 km/h
        (floor(random()*2000))::int             AS vcount,
        random() < 0.15                         AS incident
    FROM generate_series(1, 900) g
) t;


-- ---------------------------------------------------------------------
-- 4. INDEXES (optional but realistic -- also demonstrates index types)
-- ---------------------------------------------------------------------
CREATE INDEX idx_stations_metadata   ON mobility.stations   USING gin (metadata);
CREATE INDEX idx_stations_search     ON mobility.stations   USING gin (search_doc);
CREATE INDEX idx_bikes_specs         ON mobility.bikes      USING gin (specs);
CREATE INDEX idx_bikes_tags          ON mobility.bikes      USING gin (tags);
CREATE INDEX idx_riders_preferences  ON mobility.riders     USING gin (preferences);
CREATE INDEX idx_rentals_route       ON mobility.rentals    USING gin (route);
CREATE INDEX idx_rentals_started_at  ON mobility.rentals    (started_at);
CREATE INDEX idx_rentals_rider       ON mobility.rentals    (rider_id);
CREATE INDEX idx_climate_recorded_at ON mobility.climate_readings (recorded_at);
CREATE INDEX idx_traffic_measured_at ON mobility.traffic_indicators (measured_at);


-- ---------------------------------------------------------------------
-- 5. QUICK SANITY CHECK -- row counts per table
-- ---------------------------------------------------------------------
SELECT 'stations'            AS table_name, count(*) FROM mobility.stations
UNION ALL SELECT 'bikes',               count(*) FROM mobility.bikes
UNION ALL SELECT 'riders',              count(*) FROM mobility.riders
UNION ALL SELECT 'rentals',             count(*) FROM mobility.rentals
UNION ALL SELECT 'climate_readings',    count(*) FROM mobility.climate_readings
UNION ALL SELECT 'traffic_indicators',  count(*) FROM mobility.traffic_indicators;
