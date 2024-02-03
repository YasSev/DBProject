USE project;

LOAD DATA LOCAL INFILE '/Users/yashtrivedi/Documents/Project/cleanedFiles/speedmeasurementCleaned.csv'
INTO TABLE SpeedMeasurements
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE '/Users/yashtrivedi/Documents/Project/cleanedFiles/vehiclecountsCleaned.csv'
INTO TABLE TrafficCount
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;
