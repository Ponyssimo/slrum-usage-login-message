#!/bin/bash

user=$USER

if [ ! -v $1 ]; then
    user=$1
fi

maxJob=0
maxMem=0
minJob=0
minMem=0
currJob=""
currMem=0
currReq=0
accum=0
count=0

while read -r line; do
    echo "line: $line"
    info=$(echo $line | cut -d '|' -f 2)
    echo "$info"
    if [ "$info" == "TRESUsageInTot" ]; then
        echo "skipping"
        continue
    fi
    if [  "$info" != "" ]; then
        usage=$(echo $info | cut -d ',' -f 4 | tr -d -c 0-9)
        #need to check within current job for max here
        if [ $usage > $currMem ]; then
            currMem=$usage
        fi
    else
        if [ "$currJob" != 0 ]; then
            percent=$(awk "BEGIN { pc=100*${currMem}/${currReq}; i=int(pc); print (pc-i<0.5)?i:i+1 }")
            if [ "$percent" > "$maxMem" ]; then
                maxJob=$currJob
                maxMem=$percent
            fi
            if [ "$percent" < "$minMem" ] || [ minJob == 0 ]; then
                minJob=$currJob
                minMem=$percent
            fi
            ((accum+=$percent))
        fi
        #need to check previous job for max and min here
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
        ((count++))
        #should probably reset job specific variables
        currMem=0
    fi
    echo "$count"
    echo -e "done\n"
done < <(sacct --starttime=now-2weeks --endtime=now --state=COMPLETED -u $user --format jobid,TRESUsageInTot,ReqMem -p)

echo "$accum / $count"

avg=$((accum / count))

echo "$avg%"
