. ~/.xsession-envsetup

# gpg-agent
if [ -f ~/.gpg-agent-info ]
then
    eval export `cat ~/.gpg-agent-info`
fi
/usr/bin/gpg-agent > /dev/null 2> /dev/null
if [ "$?" -ne 0 ]
then
    # old file, we need to start it again
    eval `/usr/bin/gpg-agent --daemon --write-env-file`
fi

xrdb -merge ~/.Xresources
xrdb -merge ~/.Xdefaults

KBD_LAYOUT=${KEYBOARD_LANGUAGE:-us}
setxkbmap -option caps:escape,compose:menu ${KBD_LAYOUT}

xautolock -locker 'bash -c "scrot ~/.lockscreen.png; convert ~/.lockscreen.png -quality 10 -scale 5% -scale 2000% ~/.lockscreen.png; i3lock -i ~/.lockscreen.png"' -detectsleep &
bash -c 'dbus-monitor --system "type=signal,interface=org.freedesktop.login1.Manager" | while read -r line; do if echo $line | grep --quiet true; then xautolock -locknow; fi; done' &

klipper &
volumeicon &

. ~/.xsession-exec

/usr/bin/i3

# tear-down
killall gpg-agent
