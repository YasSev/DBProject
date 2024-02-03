import speedmeasurements
import vehiclecounts
import time

# Cleaning both datasets; datasets have to be in the correct directory

tStart = time.time()

print("Cleaning speed measurements dataset")
speed_file = 'DataSources/100097.csv'
speedmeasurements.cleanData(speed_file)

print("Cleaning vehicle counts dataset")
vehicle_file = 'DataSources/100006.csv'
vehiclecounts.cleanData(vehicle_file)

tEnd = time.time()
print("Time needed for data cleaning: ", tEnd - tStart)
