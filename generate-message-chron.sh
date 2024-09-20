#!/bin/bash

dir=$(dirname "$0")
filedir="$dir/messages.txt"

if [ -f $filedir ]; then
    rm $filedir
fi
touch $filedir

while read -r line; do
    currUser=$(echo $line | cut -d '|' -f 1)
    if [ $currUser == User ]; then
        continue
    fi
    echo "$currUser" >> $filedir
    ("$dir/generate-login-message.sh" $currUser) >> $filedir
done< <(sacctmgr show user -P)
