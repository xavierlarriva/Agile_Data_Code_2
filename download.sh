#!/usr/bin/env bash
#
# Script to download data for book
#
mkdir data

#
# Get airplane data
#

# Get on-time records for all flights in 2015 - 273MB
curl -Lko $PROJECT_HOME/data/On_Time_On_Time_Performance_2015.csv.bz2 \
    http://s3.amazonaws.com/agile_data_science/On_Time_On_Time_Performance_2015.csv.bz2

# Get openflights data
curl -Lko /tmp/airports.dat https://raw.githubusercontent.com/jpatokal/openflights/master/data/airports.dat
mv /tmp/airports.dat $PROJECT_HOME/data/airports.csv

curl -Lko /tmp/airlines.dat https://raw.githubusercontent.com/jpatokal/openflights/master/data/airlines.dat
mv /tmp/airlines.dat $PROJECT_HOME/data/airlines.csv

curl -Lko /tmp/routes.dat https://raw.githubusercontent.com/jpatokal/openflights/master/data/routes.dat
mv /tmp/routes.dat $PROJECT_HOME/data/routes.csv

curl -Lko /tmp/countries.dat https://raw.githubusercontent.com/jpatokal/openflights/master/data/countries.dat
mv /tmp/countries.dat $PROJECT_HOME/data/countries.csv

# Get FAA data
curl -Lko $PROJECT_HOME/data/aircraft.txt http://av-info.faa.gov/data/ACRef/tab/aircraft.txt
curl -Lko $PROJECT_HOME/data/ata.txt http://av-info.faa.gov/data/ACRef/tab/ata.txt
curl -Lko $PROJECT_HOME/data/compt.txt http://av-info.faa.gov/data/ACRef/tab/compt.txt
curl -Lko $PROJECT_HOME/data/engine.txt http://av-info.faa.gov/data/ACRef/tab/engine.txt
curl -Lko $PROJECT_HOME/data/prop.txt http://av-info.faa.gov/data/ACRef/tab/prop.txt

# Features computed for chapter 8 example
curl -Lko /tmp/simple_flight_delay_features.jsonl.bz2 http://s3.amazonaws.com/agile_data_science/simple_flight_delay_features.jsonl.bz2
mv /tmp/simple_flight_delay_features.jsonl.bz2 $PROJECT_HOME/data/simple_flight_delay_features.jsonl.bz2

# Download parquet data for examples
curl -Lko /tmp/on_time_performance.parquet.tgz http://s3.amazonaws.com/agile_data_science/on_time_performance.parquet.tgz
tar -xvzf /tmp/on_time_performance.parquet.tgz -C $PROJECT_HOME/data/

# Download january data for examples
curl -Lko /tmp/january_performance.parquet.tgz http://s3.amazonaws.com/agile_data_science/january_performance.tgz
tar -xvzf /tmp/january_performance.parquet.tgz -C $PROJECT_HOME/data/
