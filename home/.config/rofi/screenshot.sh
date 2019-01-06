#!/bin/bash

ACTION=$(cat <<EOF | rofi -dmenu -p "screenshot: " -kb-custom-1 "Alt+Return"
All screens
Focused window
Select window or area
EOF
)
EXIT="$?"

if [ "$EXIT" = "1" ]
then
    exit
fi

if [ "$EXIT" = "10" ]
then

    if [ "$ACTION" = "All screens" ]
    then
        maim | xclip -selection clipboard -t image/png
    elif [ "$ACTION" = "Focused window" ]
    then
        maim -i "$(xdotool getactivewindow)" | xclip -selection clipboard -t image/png
    elif [ "$ACTION" = "Select window or area" ]
    then
        maim -s | xclip -selection clipboard -t image/png
    fi

else

    mkdir -p ~/Pictures/Screenshots || exit
    cd ~/Pictures/Screenshots || exit

    if [ "$ACTION" = "All screens" ]
    then
        maim "$(date --iso-8601=seconds).png"
    elif [ "$ACTION" = "Focused window" ]
    then
        maim -i "$(xdotool getactivewindow)" "$(date --iso-8601=seconds).png"
    elif [ "$ACTION" = "Select window or area" ]
    then
        maim -s "$(date --iso-8601=seconds).png"
    fi

fi
