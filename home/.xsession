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

klipper &
# /usr/bin/xscreensaver -nosplash &
volumeicon &

. ~/.xsession-exec

/usr/bin/i3

# tear-down
killall gpg-agent
