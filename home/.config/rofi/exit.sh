#! /bin/bash

function close_windows {
    i3-msg '[class="^.*$"]' kill
    sleep 2
}

op=`printf "Shutdown\nReboot\nExit i3" | rofi -dmenu -l 3 -i -p "Select Option"`
if [ "$op" = "Shutdown" ]; then
    close_windows
    systemctl poweroff
elif [ "$op" = "Reboot" ]; then
    close_windows
    systemctl reboot
elif [ "$op" = "Exit i3" ]; then
    i3-msg 'exit'
fi
