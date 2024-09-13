#!/bin/bash

user=$USER

if [ ! -v $1 ]; then
    user=$1
fi

maxJob=0
maxMem=0
minJob=0
minMem=0
currJob=0
currMem=0
currReq=0
accum=0
count=0

while read -r line; do
    info=$(echo $line | cut -d '|' -f 2)
    if [ "$info" == "TRESUsageInTot" ]; then
        continue
    fi
    if [  "$info" != "" ]; then
        if [ $currReq -eq 1024 ]; then
            continue
        fi
        usage=$(echo $info | cut -d ',' -f 4 | tr -d -c 0-9)
        ((currMem+=$usage))
    else
        if [ $currJob != 0 ]; then
            percent=$(awk "BEGIN { pc=100*${currMem}/${currReq}; i=int(pc); print (pc-i<0.5)?i:i+1 }")
            if [ $percent -gt $maxMem ]; then
                maxJob=$currJob
                maxMem=$percent
            fi
            if [ $percent -lt $minMem ] || [ $minMem -eq 0 ]; then
                minJob=$currJob
                minMem=$percent
            fi
            ((accum+=$percent))
        fi
        currJob=$(echo $line | cut -d '|' -f 1)
        req=$(echo $line | cut -d '|' -f 3)
        if [ "$(echo "$req" | tr -d 0-9)" == "K" ]; then
            currReq=$(echo "$req" | tr -d -c 0-9)
        elif [ "$(echo "$req" | tr -d 0-9)" == "M" ]; then
            ((currReq=1024 * $(echo "$req" | tr -d -c 0-9)))
        elif [ "$(echo "$req" | tr -d 0-9)" == "G" ]; then
            ((currReq=1048576 * $(echo "$req" | tr -d -c 0-9)))
        elif [ "$(echo "$req" | tr -d 0-9)" == "T" ]; then
            ((currReq=1073741824 * $(echo "$req" | tr -d -c 0-9)))
        fi
        if [ $currReq -ne 1024 ]; then
            ((count++))
        fi
        currMem=0
    fi
done < <(sacct --starttime=now-2weeks --endtime=now --state=COMPLETED -u $user --format jobid,TRESUsageInTot,ReqMem -p)

if [ $currJob != 0 ]; then
    percent=$(awk "BEGIN { pc=100*${currMem}/${currReq}; i=int(pc); print (pc-i<0.5)?i:i+1 }")
    if [ $percent -gt $maxMem ]; then
        maxJob=$currJob
        maxMem=$percent
    fi
    if [ $percent -lt $minMem ] || [ minMem == 0 ]; then
        minJob=$currJob
        minMem=$percent
    fi
    ((accum+=$percent))
fi

if [ $count -ne 0 ]; then
    avg=$((accum / count))

    echo "Your worst performing recent job was job number $minJob with $minMem% memory usage"
    echo "Your average recent memory usage was $avg%"
fi
