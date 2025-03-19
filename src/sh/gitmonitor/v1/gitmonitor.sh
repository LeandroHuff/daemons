#!/bin/bash

VERSION="1.0.0"
START=$(( $(date +%s%N) / 1000000 ))
LOGFILE="/tmp/gitmonitor.log"
SECS=300
MINS=$((SECS/60))

if [[ "$1" == "-i" || "$1" == "--install" ]] ; then

    sudo cat << EOT > /etc/system.d/system/gitmonitor.service
[Unit]
Description=Git (Status/Commit/Push) Monitor
After=network.target

[Service]
Type=simple
ExecStart=/bin/bash /usr/local/bin/gitmonitor.sh
WorkingDirectory=/var/home/leandro
User=leandro
Group=leandro
Restart=on-failure
RestartSec=60
StartLimitBurst=5

[Install]
WantedBy=multi-user.target
EOT
    sudo cp ./gitmonitor.sh /usr/local/bin/

elif [[ "$1" == "-h" || "$1" == "--help" ]] ; then

cat << EOT
File to run a shell script program as a daemon.
Version: $VERSION
Usage: $(basename "$0") or $(basename "$0") -h | -i
Option:
 -h | --help        Show this help information.
 -i | --install     Prepare and install all files on each system folders.

Obs.: Call shell script with no parameters mean run the shell script program as daemon.
EOT

else

    echo > $LOGFILE

    cd /var/home/leandro
    if [ $? -ne 0 ] ; then
        echo "error   : change dir to /var/home/leandro" >> $LOGFILE
        exit 1
    fi

    while [ true ]
    do
        echo >> $LOGFILE
        DATE=$(date)
        echo "date    : $DATE" >> $LOGFILE

        NOW=$(( $(date +%s%N) / 1000000 ))
        RUNTIME=$((NOW-START))
        printf -v ELAPSED "%5u.%03u" $((RUNTIME / 1000)) $((RUNTIME % 1000))
        echo "runtime : ${ELAPSED}s" >> $LOGFILE

        STS=$(git status)
        if [[ $(echo "$STS" | grep -F "up to date"       ) ||    \
            $(echo "$STS" | grep -F "nothing to commit") ]] && \
        [[ ! $(echo "$STS" | grep -F "modified" ) && \
            ! $(echo "$STS" | grep -F "untracked") && \
            ! $(echo "$STS" | grep -F "deleted"  ) ]]
        then
            echo "success : nothing to do" >> $LOGFILE
        else
            RES=$(git add .)
            if [ $? -ne 0 ] ; then
                echo "error   : add" >> $LOGFILE
                echo "$RES" >> $LOGFILE
            fi

            RES=$(git commit -m "auto update at $DATE, next in ${SECS}s or ${MINS}m")
            if [ $? -ne 0 ] ; then
                echo "error   : commit" >> $LOGFILE
                echo "$RES" >> $LOGFILE
            fi

            RES=$(git push origin)
            if [ $? -ne 0 ] ; then
                echo "error   : push" >> $LOGFILE
                echo "$RES" >> $LOGFILE
            fi
        fi

        echo "interval: wait for ${SECS}s or ${MINS}m" >> $LOGFILE
        sleep $SECS
    done

fi

exit 0
