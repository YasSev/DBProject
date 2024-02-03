-- this needs to be the name of your database
USE project;
DROP DATABASE project;

-- manually checking, which street names are present

SELECT DISTINCT m1.Street
FROM measurement m1
INNER JOIN vehicle_count vc ON m1.Measurement_ID = vc.Measurement_ID
WHERE m1.Street IS NOT NULL;

SELECT DISTINCT m1.Street
FROM measurement m1
INNER JOIN velocity vc ON m1.Measurement_ID = vc.Measurement_ID
WHERE m1.Street IS NOT NULL;

-- Create unique Street names for vehicle count measurements

CREATE TEMPORARY TABLE temp_distinct_streets_count AS
SELECT DISTINCT m.Street
FROM measurement m
INNER JOIN vehicle_count vc ON m.Measurement_ID = vc.Measurement_ID;

CREATE TEMPORARY TABLE temp_distinct_streets_velocity AS
SELECT DISTINCT m.Street
FROM measurement m
INNER JOIN velocity vc ON m.Measurement_ID = vc.Measurement_ID;

SELECT DISTINCT tsv.Street
FROM temp_distinct_streets_velocity tsv
WHERE EXISTS (
  SELECT 1
  FROM temp_distinct_streets_count tsc
  WHERE tsc.Street LIKE CONCAT('%', tsv.Street, '%')
)
ORDER BY tsv.Street;

SELECT * FROM temp_distinct_streets_count
ORDER BY Street;

SELECT * FROM temp_distinct_streets_velocity
ORDER BY Street;

-- Update Measurements Table and Convert Geopoints back to POINT data type, from VARCHAR

ALTER TABLE measurement
ADD COLUMN Point POINT;

UPDATE measurement
SET Point = ST_PointFromText(CONCAT('POINT(', SUBSTRING_INDEX(Geopoint, ', ', -1), ' ', SUBSTRING_INDEX(Geopoint, ', ', 1), ')'))
WHERE Geopoint IS NOT NULL AND Geopoint != '';

-- Create unique GeoPoints for the two tables

DROP TABLE IF EXISTS temp_distinct_geopoint_vc;
DROP TABLE IF EXISTS temp_distinct_geopoint_vel;

CREATE TEMPORARY TABLE temp_distinct_geopoint_vc AS
SELECT DISTINCT m.Point, m.Geopoint
FROM measurement m
INNER JOIN vehicle_count vc ON m.Measurement_ID = vc.Measurement_ID;

CREATE TEMPORARY TABLE temp_distinct_geopoint_vel AS
SELECT DISTINCT m.Point, m.Geopoint
FROM measurement m
INNER JOIN velocity vc ON m.Measurement_ID = vc.Measurement_ID;

SELECT * FROM temp_distinct_geopoint_vc;

SELECT * FROM temp_distinct_geopoint_vel;

-- Create tables of points, where the geopoints lies within a "close" radius of 50/100/200

DROP TABLE IF EXISTS close_points_50;
DROP TABLE IF EXISTS close_points_100;
DROP TABLE IF EXISTS close_points_200;

CREATE TABLE close_points_50
SELECT
    vc.Point AS VC_GeoPoint,
    vc.Geopoint AS VC_GeoPoint_var,
    vel.Point AS VEL_GeoPoint,
    vel.Geopoint AS VEL_GeoPoint_var
FROM
    temp_distinct_geopoint_vc vc,
    temp_distinct_geopoint_vel vel
WHERE
    ST_Distance_Sphere(vc.Point, vel.Point) <= 50;

CREATE TABLE close_points_100
SELECT
    vc.Point AS VC_GeoPoint,
    vc.Geopoint AS VC_GeoPoint_var,
    vel.Point AS VEL_GeoPoint,
    vel.Geopoint AS VEL_GeoPoint_var
FROM
    temp_distinct_geopoint_vc vc,
    temp_distinct_geopoint_vel vel
WHERE
    ST_Distance_Sphere(vc.Point, vel.Point) <= 100;

CREATE TABLE close_points_200
SELECT
    vc.Point AS VC_GeoPoint,
    vc.Geopoint AS VC_GeoPoint_var,
    vel.Point AS VEL_GeoPoint,
    vel.Geopoint AS VEL_GeoPoint_var
FROM
    temp_distinct_geopoint_vc vc,
    temp_distinct_geopoint_vel vel
WHERE
    ST_Distance_Sphere(vc.Point, vel.Point) <= 200;

SELECT COUNT(*) FROM close_points_50;
SELECT COUNT(*) FROM close_points_100;
SELECT COUNT(*) FROM close_points_200;

-- We decide to use 100m as the "closeness" Reference for our data
-- Create new tables with the data relevant for our analysis goal
-- For this we only use "close" measurement stations

CREATE TABLE close_measurements AS
SELECT m.*
FROM measurement m
INNER JOIN close_points_100 cp
ON m.Geopoint = cp.VC_GeoPoint_var OR m.Geopoint = cp.VEL_GeoPoint_var;

CREATE TABLE new_vehicle_count AS
SELECT vc.*
FROM vehicle_count vc
INNER JOIN close_measurements cm
ON vc.Measurement_ID = cm.Measurement_ID;

CREATE TABLE new_velocity AS
SELECT vel.*
FROM velocity vel
INNER JOIN close_measurements cm
ON vel.Measurement_ID = cm.Measurement_ID;

SELECT COUNT(*) FROM close_measurements;
SELECT COUNT(*) FROM new_vehicle_count;
SELECT COUNT(*) FROM new_velocity;

-- Create Temporary Tables to find out, if there are measurements of both velocity and vehicle count
-- happening on the same date, or not

CREATE TABLE vc_date AS
SELECT vc.*, cm.Date, cm.Hour, cm.Street, cm. Geopoint, cm.Point
FROM new_vehicle_count vc
INNER JOIN close_measurements cm
ON vc.Measurement_ID = cm.Measurement_ID;

CREATE TABLE vel_date AS
SELECT vel.*, cm.Date, cm.Hour, cm.Street, cm. Geopoint, cm.Point
FROM new_velocity vel
INNER JOIN close_measurements cm
ON vel.Measurement_ID = cm.Measurement_ID;

-- Drop all Points at Lindenhofstrasse, since they don't have a corresponding counterpart
-- in the vehicle count dataset, but are still in the close points dataset
-- We found this out, by inspecting the map in Power BI

DELETE FROM vel_date
WHERE vel_date.Street = 'Lindenhofstrasse';

SELECT COUNT(DISTINCT vc.Point) FROM vc_date vc;
SELECT COUNT(DISTINCT vel.Point) FROM vel_date vel;

-- Also update or delete all other points, where we found out by looking on the map, that they are not
-- corresponding to the same street.
SET @target_point = (SELECT DISTINCT v.Point FROM vel_date v WHERE v.Geopoint = '47.54284527862306, 7.584511581055648');
SET @target_geopoint = (SELECT DISTINCT v.Geopoint FROM vel_date v WHERE v.Geopoint = '47.54284527862306, 7.584511581055648');
SELECT @target_point;
SELECT @target_geopoint;

UPDATE vel_date AS vel
SET
    vel.Point = (@target_point),
    vel.Geopoint = (@target_geopoint)
WHERE
    vel.Geopoint = '47.54301974645416, 7.584266731369311';

SELECT DISTINCT vel.Geopoint FROM vel_date vel;

-- Delete some more statsions, where the Streets don't match, by looking at the map in Power BI.
DELETE FROM vc_date
WHERE vc_date.Geopoint = '47.5487720164889, 7.600745516688138';
DELETE FROM vel_date
WHERE vel_date.Geopoint = '47.54874481353451, 7.601200321293068';

DELETE FROM vc_date
WHERE vc_date.Geopoint = '47.558201418773805, 7.597534724929922';
DELETE FROM vel_date
WHERE vel_date.Geopoint = '47.55803703598934, 7.598225139657806';

DELETE FROM vc_date
WHERE vc_date.Geopoint = '47.56561376684784, 7.588052664411427';
DELETE FROM vel_date
WHERE vel_date.Geopoint = '47.56620416556525, 7.588176194706264';

DELETE FROM vc_date
WHERE vc_date.Geopoint = '47.5665568071087, 7.59767325246949';
DELETE FROM vel_date
WHERE vel_date.Geopoint = '47.56636855615857, 7.596449869786274';

DELETE FROM vc_date
WHERE vc_date.Geopoint = '47.573906757555356, 7.602215583648606';
DELETE FROM vel_date
WHERE vel_date.Geopoint = '47.5731351495558, 7.602267387793005';

SELECT DISTINCT vel.Geopoint FROM vel_date vel ORDER BY vel.Geopoint;
SELECT DISTINCT vc.Geopoint FROM vc_date vc ORDER BY vc.Geopoint;

-- Administrative

SELECT * FROM vc_date;
SELECT COUNT(*) FROM vc_date;
SELECT * FROM vel_date;
SELECT COUNT(*) FROM vel_date;

-- Find out, if there are measurements in both views.

CREATE TEMPORARY TABLE same_date AS
SELECT vel.*
FROM vel_date vel
INNER JOIN vc_date vc
ON vc.Measurement_ID = vel.Measurement_ID
WHERE vc.Date = vel.Date;

SELECT COUNT(*) FROM same_date;

DROP TEMPORARY TABLE same_date;

-- Because this query result is 0, we have found out, that our suspicion, that there was never a speed
-- measurement and a vehicle count measurement on the same date, is true
-- -> We have to find other means to achieve our analysis goal.

-- Filter weekdays
DROP VIEW IF EXISTS mondays_only;
DROP VIEW IF EXISTS wednesdays_only;
DROP VIEW IF EXISTS fridays_only;
DROP VIEW IF EXISTS saturdays_only;
DROP VIEW IF EXISTS sundays_only;

CREATE VIEW mondays_only AS
SELECT *
FROM vc_date vc
WHERE DAYOFWEEK(vc.Date) = 2;

CREATE VIEW wednesdays_only AS
SELECT *
FROM vc_date vc
WHERE DAYOFWEEK(vc.Date) = 4;

CREATE VIEW fridays_only AS
SELECT *
FROM vc_date vc
WHERE DAYOFWEEK(vc.Date) = 6;

CREATE VIEW saturdays_only AS
SELECT *
FROM vc_date vc
WHERE DAYOFWEEK(vc.Date) = 7;

CREATE VIEW sundays_only AS
SELECT *
FROM vc_date vc
WHERE DAYOFWEEK(vc.Date) = 1;

SELECT * FROM mondays_only;

-- Group by average per hour
DROP VIEW IF EXISTS res_monday_vc_avg;
DROP VIEW IF EXISTS res_wednesday_vc_avg;
DROP VIEW IF EXISTS res_friday_vc_avg;
DROP VIEW IF EXISTS res_saturday_vc_avg;
DROP VIEW IF EXISTS res_sunday_vc_avg;

CREATE VIEW res_monday_vc_avg AS
SELECT hour AS Hour, AVG(total) AS AverageTotalPerHour
FROM mondays_only
GROUP BY Hour
ORDER BY AverageTotalPerHour DESC;

CREATE VIEW res_wednesday_vc_avg AS
SELECT hour AS Hour, AVG(total) AS AverageTotalPerHour
FROM wednesdays_only
GROUP BY Hour
ORDER BY AverageTotalPerHour DESC;

CREATE VIEW res_friday_vc_avg AS
SELECT hour AS Hour, AVG(total) AS AverageTotalPerHour
FROM fridays_only
GROUP BY Hour
ORDER BY AverageTotalPerHour DESC;

CREATE VIEW res_saturday_vc_avg AS
SELECT hour AS Hour, AVG(total) AS AverageTotalPerHour
FROM saturdays_only
GROUP BY Hour
ORDER BY AverageTotalPerHour DESC;

CREATE VIEW res_sunday_vc_avg AS
SELECT hour AS Hour, AVG(total) AS AverageTotalPerHour
FROM sundays_only
GROUP BY Hour
ORDER BY AverageTotalPerHour DESC;

-- Filter weekdays for average speed
DROP VIEW IF EXISTS mondays_only_speed;
DROP VIEW IF EXISTS wednesdays_only_speed;
DROP VIEW IF EXISTS fridays_only_speed;
DROP VIEW IF EXISTS saturdays_only_speed;
DROP VIEW IF EXISTS sundays_only_speed;

CREATE VIEW mondays_only_speed AS
SELECT *
FROM vel_date vel
WHERE DAYOFWEEK(vel.Date) = 2;

CREATE VIEW wednesdays_only_speed AS
SELECT *
FROM vel_date vel
WHERE DAYOFWEEK(vel.Date) = 4;

CREATE VIEW fridays_only_speed AS
SELECT *
FROM vel_date vel
WHERE DAYOFWEEK(vel.Date) = 6;

CREATE VIEW saturdays_only_speed AS
SELECT *
FROM vel_date vel
WHERE DAYOFWEEK(vel.Date) = 7;

CREATE VIEW sundays_only_speed AS
SELECT *
FROM vel_date vel
WHERE DAYOFWEEK(vel.Date) = 1;

-- group by average speed
DROP VIEW IF EXISTS res_monday_vel_avg;
DROP VIEW IF EXISTS res_wednesday_vel_avg;
DROP VIEW IF EXISTS res_friday_vel_avg;
DROP VIEW IF EXISTS res_saturday_vel_avg;
DROP VIEW IF EXISTS res_sunday_vel_avg;

CREATE VIEW res_monday_vel_avg AS
SELECT hour AS Hour, AVG(Speed) AS AverageSpeedPerHour
FROM mondays_only_speed
GROUP BY Hour
ORDER BY AverageSpeedPerHour DESC;

CREATE VIEW res_wednesday_vel_avg AS
SELECT hour AS Hour, AVG(Speed) AS AverageSpeedPerHour
FROM wednesdays_only_speed
GROUP BY Hour
ORDER BY AverageSpeedPerHour DESC;

CREATE VIEW res_friday_vel_avg AS
SELECT hour AS Hour, AVG(Speed) AS AverageSpeedPerHour
FROM fridays_only_speed
GROUP BY Hour
ORDER BY AverageSpeedPerHour DESC;

CREATE VIEW res_saturday_vel_avg AS
SELECT hour AS Hour, AVG(Speed) AS AverageSpeedPerHour
FROM saturdays_only_speed
GROUP BY Hour
ORDER BY AverageSpeedPerHour DESC;

CREATE VIEW res_sunday_vel_avg AS
SELECT hour AS Hour, AVG(Speed) AS AverageSpeedPerHour
FROM sundays_only_speed
GROUP BY Hour
ORDER BY AverageSpeedPerHour DESC;

-- Observe the type of speed Zones
SELECT DISTINCT vel.Zone
FROM vel_date vel
ORDER BY vel.Zone;

SELECT DISTINCT vel.Zone
FROM mondays_only_speed vel
ORDER BY vel.Zone;

SELECT DISTINCT vel.Zone
FROM fridays_only_speed vel
ORDER BY vel.Zone;

SELECT DISTINCT vel.Zone
FROM saturdays_only_speed vel
ORDER BY vel.Zone;

SELECT DISTINCT vel.Zone
FROM sundays_only_speed vel
ORDER BY vel.Zone;

-- This means that the possible Zones in our Dataset are: 20, 30, 50, 60, 80 (on all weekdays)

-- Find a good measuring station pair:
SELECT COUNT(DISTINCT mo.Date)
FROM mondays_only mo
GROUP BY mo.Geopoint
ORDER BY mo.Geopoint;

SELECT COUNT(DISTINCT mo.Date)
FROM mondays_only_speed mo
GROUP BY mo.Geopoint
ORDER BY mo.Geopoint;

SELECT DISTINCT mo.Geopoint
FROM mondays_only_speed mo
ORDER BY mo.Geopoint;

-- This means that the following measuring station had the most different days with speed measurings:

SELECT COUNT(DISTINCT mo.Date)
FROM mondays_only_speed mo
WHERE mo.Geopoint = '47.54284527862306, 7.584511581055648';

-- Repeat for the other measuring stations:

SELECT COUNT(DISTINCT mo.Date)
FROM wednesdays_only mo
GROUP BY mo.Geopoint
ORDER BY mo.Geopoint;

SELECT COUNT(DISTINCT mo.Date)
FROM wednesdays_only_speed mo
GROUP BY mo.Geopoint
ORDER BY mo.Geopoint;

SELECT DISTINCT mo.Geopoint
FROM wednesdays_only_speed mo
ORDER BY mo.Geopoint;

SELECT COUNT(DISTINCT mo.Date)
FROM fridays_only mo
GROUP BY mo.Geopoint
ORDER BY mo.Geopoint;

SELECT COUNT(DISTINCT mo.Date)
FROM fridays_only_speed mo
GROUP BY mo.Geopoint
ORDER BY mo.Geopoint;

SELECT DISTINCT mo.Geopoint
FROM fridays_only_speed mo
ORDER BY mo.Geopoint;

SELECT COUNT(DISTINCT mo.Date)
FROM saturdays_only mo
GROUP BY mo.Geopoint
ORDER BY mo.Geopoint;

SELECT COUNT(DISTINCT mo.Date)
FROM saturdays_only_speed mo
GROUP BY mo.Geopoint
ORDER BY mo.Geopoint;

SELECT DISTINCT mo.Geopoint
FROM saturdays_only_speed mo
ORDER BY mo.Geopoint;

SELECT COUNT(DISTINCT mo.Date)
FROM sundays_only mo
GROUP BY mo.Geopoint
ORDER BY mo.Geopoint;

SELECT COUNT(DISTINCT mo.Date)
FROM sundays_only_speed mo
GROUP BY mo.Geopoint
ORDER BY mo.Geopoint;

SELECT DISTINCT mo.Geopoint
FROM sundays_only_speed mo
ORDER BY mo.Geopoint;

SELECT DISTINCT mo.Geopoint, mo.Street
FROM sundays_only_speed mo
ORDER BY mo.Geopoint;

-- As we can nicely observe, the speed measuring station with Geopoint '47.54284527862306, 7.584511581055648'
-- located at 'Gundelingerstrasse' has the most different speed measurings of all points, across all weekdays.
-- This is likely because we rewrote the Geopoints of one speed measuring station to this one, which
-- was very close, and thus deemed identical (when looking at the map in PowerBI).

-- The corresponding measuring station for vehicle counts is: '47.54273560620849, 7.584995701861084'

-- As we have the most data points at this station, we will subsequently take a closer look at this individual station.

-- Group by average per hour for station 'Gundelingerstrasse'
DROP VIEW IF EXISTS res_monday_vc_spec;
DROP VIEW IF EXISTS res_wednesday_vc_spec;
DROP VIEW IF EXISTS res_friday_vc_spec;
DROP VIEW IF EXISTS res_saturday_vc_spec;
DROP VIEW IF EXISTS res_sunday_vc_spec;

CREATE VIEW res_monday_vc_spec AS
SELECT hour AS Hour, AVG(total) AS AverageTotalPerHour
FROM mondays_only
WHERE mondays_only.Geopoint = '47.54273560620849, 7.584995701861084'
GROUP BY Hour
ORDER BY AverageTotalPerHour DESC;

CREATE VIEW res_wednesday_vc_spec AS
SELECT hour AS Hour, AVG(total) AS AverageTotalPerHour
FROM wednesdays_only
WHERE wednesdays_only.Geopoint = '47.54273560620849, 7.584995701861084'
GROUP BY Hour
ORDER BY AverageTotalPerHour DESC;

CREATE VIEW res_friday_vc_spec AS
SELECT hour AS Hour, AVG(total) AS AverageTotalPerHour
FROM fridays_only
WHERE fridays_only.Geopoint = '47.54273560620849, 7.584995701861084'
GROUP BY Hour
ORDER BY AverageTotalPerHour DESC;

CREATE VIEW res_saturday_vc_spec AS
SELECT hour AS Hour, AVG(total) AS AverageTotalPerHour
FROM saturdays_only
WHERE saturdays_only.Geopoint = '47.54273560620849, 7.584995701861084'
GROUP BY Hour
ORDER BY AverageTotalPerHour DESC;

CREATE VIEW res_sunday_vc_spec AS
SELECT hour AS Hour, AVG(total) AS AverageTotalPerHour
FROM sundays_only
WHERE sundays_only.Geopoint = '47.54273560620849, 7.584995701861084'
GROUP BY Hour
ORDER BY AverageTotalPerHour DESC;

-- group by average speed per hour for station 'Gundelingerstrasse'
DROP VIEW IF EXISTS res_monday_vel_spec;
DROP VIEW IF EXISTS res_wednesday_vel_spec;
DROP VIEW IF EXISTS res_friday_vel_spec;
DROP VIEW IF EXISTS res_saturday_vel_spec;
DROP VIEW IF EXISTS res_sunday_vel_spec;

CREATE VIEW res_monday_vel_spec AS
SELECT hour AS Hour, AVG(Speed) AS AverageSpeedPerHour
FROM mondays_only_speed
WHERE mondays_only_speed.Geopoint = '47.54284527862306, 7.584511581055648'
GROUP BY Hour
ORDER BY AverageSpeedPerHour DESC;

CREATE VIEW res_wednesday_vel_spec AS
SELECT hour AS Hour, AVG(Speed) AS AverageSpeedPerHour
FROM wednesdays_only_speed
WHERE wednesdays_only_speed.Geopoint = '47.54284527862306, 7.584511581055648'
GROUP BY Hour
ORDER BY AverageSpeedPerHour DESC;

CREATE VIEW res_friday_vel_spec AS
SELECT hour AS Hour, AVG(Speed) AS AverageSpeedPerHour
FROM fridays_only_speed
WHERE fridays_only_speed.Geopoint = '47.54284527862306, 7.584511581055648'
GROUP BY Hour
ORDER BY AverageSpeedPerHour DESC;

CREATE VIEW res_saturday_vel_spec AS
SELECT hour AS Hour, AVG(Speed) AS AverageSpeedPerHour
FROM saturdays_only_speed
WHERE saturdays_only_speed.Geopoint = '47.54284527862306, 7.584511581055648'
GROUP BY Hour
ORDER BY AverageSpeedPerHour DESC;

CREATE VIEW res_sunday_vel_spec AS
SELECT hour AS Hour, AVG(Speed) AS AverageSpeedPerHour
FROM sundays_only_speed
WHERE sundays_only_speed.Geopoint = '47.54284527862306, 7.584511581055648'
GROUP BY Hour
ORDER BY AverageSpeedPerHour DESC;
