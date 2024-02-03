use project;

-- Do some more data cleaning (update -1 values to NULL); see python
UPDATE SpeedMeasurements SET Zone = NULL WHERE Zone = -1;
UPDATE SpeedMeasurements SET ViolationRate = NULL WHERE ViolationRate = -1;
UPDATE SpeedMeasurements SET SpeedV50 = NULL WHERE SpeedV50 = -1;
UPDATE SpeedMeasurements SET SpeedV85 = NULL WHERE SpeedV85 = -1;
UPDATE SpeedMeasurements SET Vehicles = NULL WHERE Vehicles = -1;

UPDATE TrafficCount SET LaneCode = NULL WHERE LaneCode = -1;

-- Add primary keys to both relations and watch that they are NOT the same
ALTER TABLE SpeedMeasurements
ADD smid INT NOT NULL AUTO_INCREMENT PRIMARY KEY;
SET @maxSmId = (SELECT MAX(smid) FROM SpeedMeasurements);
ALTER TABLE TrafficCount
ADD tcid INT NOT NULL AUTO_INCREMENT PRIMARY KEY;
UPDATE TrafficCount
SET tcid = tcid + @maxSmId;

-- Check, if it worked correctly
SELECT MIN(tcid) AS minTrafficCountId FROM TrafficCount;
SELECT MAX(smid) AS maxSpeedMeasurementsId FROM SpeedMeasurements;

SELECT
    s.smid,
    t.tcid
FROM
    SpeedMeasurements s
JOIN
    TrafficCount t ON s.smid = t.tcid;


-- Insert Data in integrated tables for SpeedMeasurements Table

INSERT INTO Measurement (Measurement_ID, Hour, Date, Street, Geopoint)
SELECT smid, HOUR(DateTime), Date, Street, Geopoint
FROM SpeedMeasurements;

INSERT INTO Velocity (Measurement_ID, Time, Speed, Zone, Vehicle_length)
SELECT smid, Time, Speed, Zone, VehicleLength
FROM SpeedMeasurements;

-- check if it worked Correctly for SpeedMeasurements

SELECT *
FROM Measurement
JOIN Velocity ON Measurement.Measurement_ID = Velocity.Measurement_ID
LIMIT 10;

SELECT
    smid,
    HOUR(DateTime) AS Hour,
    Date,
    Street,
    Geopoint,
    Time,
    Speed,
    Zone,
    VehicleLength
FROM
    SpeedMeasurements
LIMIT 10;


-- Insert Data in integrated tables for TrafficCount Table

INSERT INTO Measurement (Measurement_ID, Hour, Date, Street, Geopoint)
SELECT tcid, HourFrom, Date, SiteName, Geopoint
FROM TrafficCount;

INSERT INTO Vehicle_count (Measurement_ID, Total, Delivery_van_count, Motorcycle_count, Car_count, Lorry_count, Bus_count)
SELECT tcid, Total, Lief + LiefAufl + LiefPlus, MR, PW + PWPlus, LW + LWPlus + Sattelzug, Bus
FROM TrafficCount;

-- Check if it worked correctly for TrafficCount:

SELECT *
FROM Measurement
JOIN Vehicle_count ON Measurement.Measurement_ID = Vehicle_count.Measurement_ID
LIMIT 10;

SELECT
    tcid,
    Total,
    Lief + LiefPlus + LiefAufl,
    MR,
    PW + PWPlus,
    LW + LWPlus + Sattelzug,
    Bus
FROM
    TrafficCount
LIMIT 10;
