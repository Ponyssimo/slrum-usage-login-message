#!/bin/bash

while read -r line; do
    currUser=$(echo $line | cut -d '|' -f 1)
    if [ $currUser == User ]; then
        continue
    fi
    filedir="/var/spool/motd/$currUser"

    if [ -f $filedir ]; then
        rm $filedir
    fi

    message=$("$dir/generate-login-message.sh" $currUser)
    
    if [ $message != "" ]; then
        touch $filedir
        echo "$message" > $filedir
    fi
done< <(sacctmgr show user -P)
