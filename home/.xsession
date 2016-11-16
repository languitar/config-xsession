#!/usr/bin/env sh
. ~/.xsession-envsetup || true

# ssh-agent
eval `ssh-agent`

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

xss-lock -l ~/.transfer-lock.sh i3lock &

dunst &
volumeicon &

. ~/.xsession-exec || true

exec /usr/bin/i3

# tear-down
killall gpg-agent
