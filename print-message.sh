#!/bin/bash

user=$USER

# If a user is specified, use that user instead of the user running the command
if [ ! -v $1 ]; then
    user=$1
fi

# Set the current file path for the user
filedir="/var/spool/motd/$user"

# If the user has a message, loop through each line and print it
if [ -e $filedir ]; then
    while read -r line; do
        echo -e "$line"
    done < "$filedir"
fi
