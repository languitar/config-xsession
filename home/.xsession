#!/usr/bin/env sh
. ~/.xsession-envsetup || true

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

xrdb -merge ~/.Xresources || true
xrdb -merge ~/.Xdefaults || true

KBD_LAYOUT=${KEYBOARD_LANGUAGE:-us}
setxkbmap -option caps:escape,compose:menu ${KBD_LAYOUT}

# screensaver and session locking
xset s 480 dpms 620 0 0
light-locker --lock-after-screensaver=20 --lock-on-suspend --no-late-locking &

klipper &
volumeicon &

. ~/.xsession-exec || true

exec /usr/bin/i3

# tear-down
killall gpg-agent
