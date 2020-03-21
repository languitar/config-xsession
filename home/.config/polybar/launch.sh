#!/usr/bin/env bash

# Terminate already running bar instances
killall -q polybar

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null
do
    sleep 1
done

# determine if this is a laptop
acpi | grep Battery > /dev/null 2> /dev/null
is_laptop=$?

xrandr | grep ' connected' | while read -r line
do
    bar="general"
    if [[ $line = *' primary '* ]]
    then
        if [ $is_laptop -eq 0 ]
        then
            bar="laptop-main"
        else
            bar="main"
        fi
    else
        bar="general"
    fi

    MONITOR="$(echo "$line" | cut -d ' ' -f 1)" polybar --reload "${bar}" > /dev/null 2>&1 &
done
