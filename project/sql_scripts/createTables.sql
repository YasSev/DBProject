CREATE DATABASE IF NOT EXISTS project;

USE project;

DROP TABLE IF EXISTS SpeedMeasurements;
DROP TABLE IF EXISTS TrafficCount;

DROP TABLE IF EXISTS Measurement;
DROP TABLE IF EXISTS Vehicle_count;
DROP TABLE IF EXISTS Velocity;

-- Create Tables of individual data sets:

-- Table Speed measurements:

CREATE TABLE SpeedMeasurements (
    Timestamp DATETIME,
    Measurement_ID INT,
    Direction_ID INT,
    Speed INT,
    Time TIME,
    Date DATE,
    DateTime DATETIME,
    StartOfMeasurement DATE,
    EndOfMeasurement DATE,
    Zone INT,
    Location VARCHAR(50),
    Direction VARCHAR(50),
    Geopoint VARCHAR(100),
    ViolationRate FLOAT(7, 3),
    SpeedV50 INT,
    SpeedV85 INT,
    Street VARCHAR(100),
    HouseNumber VARCHAR(50),
    Vehicles INT,
    VehicleLength DECIMAL(5, 2),
    Latitude VARCHAR(50),
    Longitude VARCHAR(50)
    -- Column "Kennzahlen pro Mess-Standort" not included, as it contains a link, which only makes sense inside data.bs.ch
);

-- Table Traffic Count:

CREATE TABLE TrafficCount (
    ZST_NR INT,
    SiteCode INT,
    SiteName VARCHAR(100),
    DateTimeFrom DATETIME,
    DateTimeTo DATETIME,
    DirectionName VARCHAR(100),
    LaneCode INT,
    LaneName VARCHAR(50),
    ValuesApproved BOOLEAN,
    ValuesEdited BOOLEAN,
    TrafficType VARCHAR(50),
    Total INT,
    MR INT,
    PW INT,
    PWPlus INT,
    Lief INT,
    LiefPlus INT,
    LiefAufl INT,
    LW INT,
    LWPlus INT,
    Sattelzug INT,
    Bus INT,
    Other INT,
    Year INT,
    Month INT,
    Day INT,
    Weekday INT,
    HourFrom INT,
    Date DATE,
    TimeFrom TIME,
    TimeTo TIME,
    DayOfYear INT,
    ZST_ID INT,
    Geopoint VARCHAR(100),
    Latitude VARCHAR(50),
    Longitude VARCHAR(50)
);

-- Create Tables according to integrated Schema:

-- Create measurement table:
CREATE TABLE Measurement (
    -- we used - instead of _ in our integrated ER, because of readability
    Measurement_ID INT PRIMARY KEY,
    Hour INT,
    Date DATE,
    Street VARCHAR(255),
    Geopoint VARCHAR(255)
);

-- Create Velocity table:
CREATE TABLE Velocity (
    Measurement_ID INT PRIMARY KEY,
    Time TIME,
    Speed INT,
    Zone INT,
    Vehicle_length DECIMAL(3, 1),
    FOREIGN KEY (Measurement_ID) REFERENCES Measurement(Measurement_ID)
);

-- Create Vehicle Count table:
CREATE TABLE Vehicle_count (
    -- made some name adjustments, which are better suited for an SQL script
    Measurement_ID INT PRIMARY KEY,
    Total INT,
    Delivery_van_count INT,
    Motorcycle_count INT,
    Car_count INT,
    Lorry_count INT,
    Bus_count INT,
    FOREIGN KEY (Measurement_ID) REFERENCES Measurement(Measurement_ID)
);