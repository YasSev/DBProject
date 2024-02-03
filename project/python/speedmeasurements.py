from pathlib import Path

import pandas as pd
import numpy as np
import time

# Data cleaning of the speed measurements 2021 dataset

def cleanData(path):

    tStart = time.time()

    print("Cleaning data of speed measurements:")
    file_path = path

    print("Reading CSV:")
    data = pd.read_csv(file_path, sep=';', dtype={'Hausnummer': 'str', 'Ort': 'str', 'Geopunkt': 'str'})
    print("Finished Reading CSV")

    data.rename(columns={
        'Timestamp': 'Timestamp',
        'Messung-ID': 'Measurement_ID',
        'Richtung ID': 'Direction_ID',
        'Geschwindigkeit': 'Speed',
        'Zeit': 'Time',
        'Datum': 'Date',
        'Datum und Zeit': 'DateTime',
        'Messbeginn': 'StartOfMeasurement',
        'Messende': 'EndOfMeasurement',
        'Zone': 'Zone',
        'Ort': 'Location',
        'Richtung': 'Direction',
        'Geopunkt': 'Geopoint',
        'Übertretungsquote': 'ViolationRate',
        'Geschwindigkeit V50': 'SpeedV50',
        'Geschwindigkeit V85': 'SpeedV85',
        'Strasse': 'Street',
        'Hausnummer': 'HouseNumber',
        'Fahrzeuge': 'Vehicles',
        'Fahrzeuglänge': 'VehicleLength'
    }, inplace=True)

    # Reformatting timestamp to mySQL DATETIME format
    print("Reformatting Timestamp")
    data['Timestamp'] = pd.to_datetime(data['Timestamp'], utc=True).dt.tz_convert(None).dt.strftime("%Y-%m-%d %H:%M:%S")

    # Reformatting speed to Integer
    print("Reformatting Speed")
    data['Speed'] = data['Speed'].round().astype(int)

    # Reformatting date to mySQL DATE format
    print("Reformatting Date")
    data['Date'] = pd.to_datetime(data['Date'], format='%d.%m.%y').dt.strftime('%Y-%m-%d')

    # Reformatting DateTime to mySQL DATE format
    print("Reformatting DateTime")
    data['DateTime'] = pd.to_datetime(data['DateTime'], format="%d.%m.%y %H:%M:%S").dt.strftime("%Y-%m-%d %H:%M:%S")

    # Reformatting Zone to Integer
    print("Reformatting Zone")
    # Fill with -1, if the number is not defined
    data['Zone'] = data['Zone'].fillna(-1).round().astype(int)

    # Creating latitude and longitude
    print("Reformatting latitude and longitude")
    data[['Latitude', 'Longitude']] = data['Geopoint'].str.split(pat=',', expand=True)

    # Reformatting SpeedV50 to Integer
    print("Reformatting SpeedV50")
    # Fill with -1, if the number is not defined
    data['SpeedV50'] = data['SpeedV50'].fillna(-1).round().astype(int)

    # Reformatting SpeedV85 to Integer
    print("Reformatting SpeedV85")
    # Fill with -1, if the number is not defined
    data['SpeedV85'] = data['SpeedV85'].fillna(-1).round().astype(int)

    # Reformatting violationrate to correct decimal
    print("Reformatting ViolationRate")
    # Fill with -1, if the number is not defined
    data['ViolationRate'] = data['ViolationRate'].fillna(-1).astype(float)

    # Reformatting Vehicles to Integer
    print("Reformatting Vehicles")
    # Fill with -1, if the number is not defined
    data['Vehicles'] = data['Vehicles'].fillna(-1).round().astype(int)

    # Drop column "Kennzahlen pro Mess-Standort"
    column_to_drop = "Kennzahlen pro Mess-Standort"
    if column_to_drop in data.columns:
        # Drop the specified column
        data.drop(column_to_drop, axis=1, inplace=True)
        print(f"Column '{column_to_drop}' has been deleted.")

    #Printing all column names
    print("Column names:")
    for column in data.columns:
        print(column)
        print(data[column].iloc[0:5])

    tEnd = time.time()
    print("Time used to clean speed measurements: ", tEnd - tStart)

    print("Writing file...")
    out = Path('cleanedFiles/speedmeasurementCleaned.csv')
    out.parent.mkdir(parents=True, exist_ok=True)
    data.to_csv(out, index=False)




