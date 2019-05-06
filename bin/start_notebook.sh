#!/usr/bin/env bash

cd /home/ubuntu/Agile_Data_Code_2

nohup jupyter notebook --ip=0.0.0.0 --NotebookApp.token= --allow-root --no-browser &

echo "Jupyter notebook started!"
