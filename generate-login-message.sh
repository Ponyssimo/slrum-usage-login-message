#!/bin/bash

user=$USER

if [ ! -v $1 ]; then
    user=$1
fi

memThreshold=2097152
maxJob=0
maxMem=0
minJob=0
minMem=0
currJob=0
currMem=0
currReq=0
accum=0
count=0

# If the previous loop was a job, calculate the percent of the allocated memory used,
# then determine whether it was the most or least efficiently allocated job
function process_job {
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
}

while read -r line; do
    # Get next line, skipping the first line
    info=$(echo $line | cut -d '|' -f 2)
    if [ "$info" == "TRESUsageInTot" ]; then
        continue
    fi

    # If $line gives usage info and the requested memory is less than the allocated threshold,
    # add the memory usage to the accumulator
    if [  "$info" != "" ]; then
        if [ $currReq -lt $memThreshold ]; then
            continue
        fi
        usage=$(echo $info | cut -d ',' -f 4 | tr -d -c 0-9)
        ((currMem+=$usage))
        
    # Else, process the previous job and reset for the new job
    else
        process_job

        # Set the current job id and the amount of memory requested in KiB
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

        # If the number of cpus requested or the time elapsed are below the threshold,
        # set the requested memory to 0 so they will be skipped
        reqCPU=$(echo $line | cut -d '|' -f 4)
        if [ $reqCPU -eq 1 ]; then
            curreq=0
        fi
        startTime=$(echo $line | cut -d '|' -f 5)
        endTime=$(echo $line | cut -d '|' -f 6)
        startSec=$(date -d $startTime +"%s")
        endSec=$(date -d $endTime +"%s")
        elapsedTime=$((endSec - startSec))
        if [ $elapsedTime -lt 180 ]; then
            curreq=0
        fi

        # If the requested memory is at or above the threshold, increment the job count
        if [ $currReq -ge $memThreshold ]; then
            ((count++))
        fi

        # Reset the memory used accumulator
        currMem=0
    fi
# Get all Slurm jobs for the user
done < <(sacct --starttime=now-2weeks --endtime=now --state=COMPLETED -u $user --format jobid,TRESUsageInTot,ReqMem,ReqCPUS,Start,End -p)

process_job

# If at least one job was processed, calculate the average memory usage, then print the usage message
if [ $count -ne 0 ]; then
    avg=$((accum / count))

    echo "Your worst performing recent job was job number $minJob with $minMem% memory usage"
    echo "Your average recent memory usage was $avg%"
fi
