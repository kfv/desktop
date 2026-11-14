#!/bin/sh

xrdb -merge "$HOME/.Xresources"
setxkbmap -option ctrl:nocaps
xsetroot -bitmap "$HOME/.local/share/dot.xbm" -fg '#737373' -bg '#000000'
xset s 600 600 s noblank -dpms

xss-lock -- slock &
xbanish &
slstatus &

exec dwm
