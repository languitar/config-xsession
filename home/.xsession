#!/usr/bin/env sh
. ~/.xsession-envsetup || true

export QT_QPA_PLATFORMTHEME="qt5ct"

export PASSWORD_STORE_ENABLE_EXTENSIONS="true"

xrdb -merge ~/.Xresources || true
xrdb -merge ~/.Xdefaults || true

xset -b

xss-lock -l ~/.transfer-lock.sh i3lock &

volumeicon &

. ~/.xsession-exec || true

exec /usr/bin/i3
