#!/bin/bash

while read -r line; do
    # Get the current user, skipping the first line
    currUser=$(echo $line | cut -d '|' -f 1)
    if [ $currUser == User ]; then
        continue
    fi
    # Set the current file path for the current user
    filedir="/var/spool/motd/$currUser"

    # If a file exists for the user, delete it
    if [ -f $filedir ]; then
        rm $filedir
    fi

    # Generate the message for the current user
    message=$("$(dirname "$0")/generate-login-message.sh" $currUser)
    
    # Create a new file containing the login message
    # if the message isn't empty
    if [ "$message" != "" ]; then
        touch $filedir
        echo "$message" >> $filedir
    fi
# Get all Slurm users
done< <(sacctmgr show user -P)
