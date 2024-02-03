from pathlib import Path

import pandas as pd
import numpy as np
import time

# Data cleaning of the vehicle count dataset

def cleanData(path):

    tStart = time.time()

    print("Cleaning data of vehicle counts:")
    file_path = path

    print("Reading CSV:")
    data = pd.read_csv(file_path, sep=';')
    print("Finished Reading CSV")

    # Renaming the columns
    data.rename(columns={
        'ZST_NR': 'ZST_NR',
        'SiteCode': 'SiteCode',
        'SiteName': 'SiteName',
        'DateTimeFrom': 'DateTimeFrom',
        'DateTimeTo': 'DateTimeTo',
        'DirectionName': 'DirectionName',
        'LaneCode': 'LaneCode',
        'LaneName': 'LaneName',
        'ValuesApproved': 'ValuesApproved',
        'ValuesEdited': 'ValuesEdited',
        'TrafficType': 'TrafficType',
        'Total': 'Total',
        'MR': 'MR',
        'PW': 'PW',
        'PW+': 'PWPlus',
        'Lief': 'Lief',
        'Lief+': 'LiefPlus',
        'Lief+Aufl.': 'LiefAufl',
        'LW': 'LW',
        'LW+': 'LWPlus',
        'Sattelzug': 'Sattelzug',
        'Bus': 'Bus',
        'andere': 'Other',
        'Year': 'Year',
        'Month': 'Month',
        'Day': 'Day',
        'Weekday': 'Weekday',
        'HourFrom': 'HourFrom',
        'Date': 'Date',
        'TimeFrom': 'TimeFrom',
        'TimeTo': 'TimeTo',
        'DayOfYear': 'DayOfYear',
        'Zst_id': 'ZST_ID',
        'Geo Point': 'GeoPoint'
    }, inplace=True)

    # Reformatting dateTimeFrom to mySQL DATETIME format
    print("Reformatting DateTimeFrom")
    data['DateTimeFrom'] = pd.to_datetime(data['DateTimeFrom'], utc=True).dt.tz_convert(None).dt.strftime("%Y-%m-%d %H:%M:%S")

    # Reformatting dateTimeTo to mySQL DATETIME format
    print("Reformatting DateTimeTo")
    data['DateTimeTo'] = pd.to_datetime(data['DateTimeTo'], utc=True).dt.tz_convert(None).dt.strftime("%Y-%m-%d %H:%M:%S")

    # Reformatting Vehicles to Integer
    print("Reformatting Vehicles")
    # Fill with -1, if the number is not defined
    data['LaneCode'] = data['LaneCode'].fillna(-1).round().astype(int)

    # Reformatting date to mySQL DATE format
    print("Reformatting Date")
    data['Date'] = pd.to_datetime(data['Date'], format='%d.%m.%Y').dt.strftime('%Y-%m-%d')

    # Reformatting TimeFrom to conform with mySQL TIME format
    print("Reformatting TimeFrom")
    data['TimeFrom'] = data['TimeFrom'] + ":00"

    # Reformatting TimeTo to conform with mySQL TIME format
    print("Reformatting TimeTo")
    data['TimeTo'] = data['TimeTo'] + ":00"

    # Creating latitude and longitude
    print("Reformatting latitude and longitude")
    data[['Latitude', 'Longitude']] = data['GeoPoint'].str.split(pat=',', expand=True)


    # Printing all column names
    print("Column names:")
    for column in data.columns:
        print(column)
        print(data[column].iloc[0:5])

    tEnd = time.time()
    print("Time used to clean vehicle count: ", tEnd - tStart)

    print("Writing file...")
    out = Path('cleanedFiles/vehiclecountsCleaned.csv')
    out.parent.mkdir(parents=True, exist_ok=True)
    data.to_csv(out, index=False)


