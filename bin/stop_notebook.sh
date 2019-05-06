#!/usr/bin/env bash

ps aux|grep jupyter|tr -s ' '|cut -d ' ' -f2|xargs kill -9

echo "Killed Jupyter Notebook!"
