#!/bin/bash

user=$USER

if [ ! -v $1 ]; then
    user=$1
fi

dir=$(dirname "$0")
filedir="$dir/messages.txt"

count=0

while read -r line; do
    if [ "$line" = "$user" ]; then
        count=1
        continue
    fi
    if [ $count -eq 1 ] || [ $count -eq 2 ]; then
        lineList=( $line )
        if [ ${lineList[0]} != "Your"]; then
            break
        fi
        echo "$line"
        ((count++))
    fi
    if [ $count -eq 3 ]; then
        break
    fi
done< <(cat $filedir)

usage=$(df -Ph /home/$user | awk 'NR == 2{print $5+0}')
((usage=100-$usage))
if [ $usage -lt 5 ]; then
    echo "Warning: your available storage is $usage%"
fi
