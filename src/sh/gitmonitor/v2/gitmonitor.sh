#!/bin/bash

START=$(( $(date +%s%N) / 1000000 ))
VERSION="2.0.0"
SCRIPTNAME=$(basename "$0")
DAEMONAME=${SCRIPTNAME%.*}
LOGFILE="/tmp/$DAEMONAME.log"
SECS=300
MINS=$((SECS/60))

function unsetVars
{
    unset -v START
    unset -v VERSION
    unset -v SCRIPTNAME
    unset -v DAEMONAME
    unset -v LOGFILE
    unset -v SECS
    unset -v MINS

    unset -f error
    unset -f success
    unset -f logError
    unset -f logSuccess
    unset -f getRuntime
    unset -f logNewLIne
    unset -f logClear
    unset -f logSaveDate
    unset -f logSaveIt
    unset -f logInterval
    unset -f _help
    unset -f _install
    unset -f parseParameters
    unset -f main
}

function error
{
    echo -e "\033[91merror:\033[0m $1"
}

function success
{
    echo -e "\033[92msuccess:\033[0m $1"
}

function logError
{
    echo -e "\033[91merror:\033[0m $1" >> $LOGFILE
}

function logSuccess
{
    echo -e "\033[92msuccess:\033[0m $1" >> $LOGFILE
}

function getRuntime
{
    local NOW
    local RUNTIME
    NOW=$(( $(date +%s%N) / 1000000 ))
    RUNTIME=$((NOW-START))
    printf -v ELAPSED "%u.%03u" $((RUNTIME / 1000)) $((RUNTIME % 1000))
    echo -e "\033[97mruntime:\033[0m ${ELAPSED}s"
    unset -v ELAPSED
}

function logNewLine
{
    echo >> $LOGFILE
}

function logClear
{
    echo > $LOGFILE
}

function logSaveDate
{   
    local DATE
    DATE=$(date)
    echo "\033[97mdate:\033[0m $DATE" >> $LOGFILE
}

function logSaveIt
{   
    echo "$1" >> $LOGFILE
}

function logInterval
{
    local secs=$1
    local mins=$2
    echo -e "\033[97minterval:\033[0m Wait for ${secs}s or ${mins}m" >> $LOGFILE
}

function _help
{
cat << EOT
File to run a shell script program as a daemon.
Version: $VERSION
Usage: $(basename "$0") or $(basename "$0") -h | -i
Option:
 -h | --help        Show this help information.
 -i | --install     Prepare and install all files on each system folders.

Obs.: Call shell script with no parameters mean run the shell script program as daemon.
EOT
    return 0
}

function _install
{
    local err=0

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
    if [ $? -ne 0 ] ; then
        err=$((err+1))
        error "Copy configuration into /etc/system.d/system/gitmonitor.service file."
    fi

    sudo cp ./gitmonitor.sh /usr/local/bin/
    
    if [ $? -ne 0 ] ; then
        err=$((err+2))
        error "Copy gitmonitor.sh file to /usr/local/bin/ directory."
    fi

    return $err
}

function main
{
    local STS
    local RES
    local DATE

    while [ -n "$1" ] ; do
        case "$1" in
        -h | --help) _help ; return $? ;;
        -i | --install | install) _install ; return $? ;;
        *) error "Unknown parameter $1" ; return 1 ;;
        esac
        shift
    done
    
    logClear

    cd /var/home/leandro
    if [ $? -ne 0 ] ; then
        logError "Change to directory /var/home/leandro"
        return 1
    fi

    while [ true ]
    do
        logNewLine

        STS=$(git status)
        if [[ $(echo "$STS" | grep -F "up to date"       ) ||    \
              $(echo "$STS" | grep -F "nothing to commit") ]] && \
         [[ ! $(echo "$STS" | grep -F "modified" ) && \
            ! $(echo "$STS" | grep -F "untracked") && \
            ! $(echo "$STS" | grep -F "deleted"  ) ]]
        then
            logSuccess "Nothing to do"
        else
            RES=$(git add .)
            if [ $? -ne 0 ] ; then
                logError "git add ."
                logSaveIt "$RES"
            fi

            DATE=$(date)
            RES=$(git commit -m "auto update at $DATE, next in ${SECS}s or ${MINS}m")
            if [ $? -ne 0 ] ; then
                logError "git commit -m"
                logSaveIt "$RES"
            fi

            RES=$(git push origin)
            if [ $? -ne 0 ] ; then
                logError "git push origin"
                logSaveIt "$RES"
            fi
        fi

        logInterval $SECS $MINS
        sleep $SECS
    done
    return 0
}

main "$@"
code=$?
unsetVars
exit $code
