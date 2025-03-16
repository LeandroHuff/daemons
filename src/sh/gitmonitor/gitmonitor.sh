#!/bin/bash

LOGFILE="/var/log/gitmonitor.log"

cd /var/home/leandro/

while true
do
    git status | grep -F "modified"
    if [ $? -eq 0 ]
    then
        git add .                         || echo -e "git add . failure :("                         >> "$LOGFILE"
        git commit -m "automated updates" || echo -e "git commit -m "automated updates" failure :(" >> "$LOGFILE"
        git push origin                   || echo -e "git commit -m "automated updates" failure :(" >> "$LOGFILE"
    else
        echo -e "git status command returned code with nothing to do answer :)" >> "$LOGFILE"
    fi
    sleep 60
done
