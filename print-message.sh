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

# Get storage usage for the user and print a warning message if available space
# is less than threshold
usage=$(df -Ph /home/$user | awk 'NR == 2{print $5+0}')
((usage=100-$usage))
if [ $usage -lt 5 ]; then
    echo "Warning: your available storage is $usage%"
    echo -e "$(tput setaf 1)Warning: your available storage is $usage%$(tput sgr0)"
fi
