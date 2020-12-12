#!/bin/bash

SPLASH_SOCK=/var/run/fbi.sock

# splash chain
rm -f "$SPLASH_SOCK"
mkfifo "$SPLASH_SOCK" &&
tail -f "$SPLASH_SOCK" |
fbi -a -d /dev/fb0 -cachemem 10 -readahead -noverbose /usr/local/share/splash/{check,nowifi,stream}.jpg &
sleep 1

# install boot splash
if [ -b /dev/mmcblk0p1 ]; then
    mount /dev/mmcblk0p1 /mnt/ &&
    cp /usr/local/share/splash/boot.png /mnt/splash/balena-logo.png &&
    umount /dev/mmcblk0p1
fi

# check wifi
echo >> "$SPLASH_SOCK"
iwgetid -r

# wifi config
if [ $? -eq 0 ]; then
    echo >> "$SPLASH_SOCK"
    echo 'Skipping WiFi Connect'
    sleep 1
else
    echo >> "$SPLASH_SOCK"
    echo 'Starting WiFi Connect'
    wifi-connect
fi

# start stream
echo >> "$SPLASH_SOCK"
VIDEO=$(youtube-dl -f mp4 -g "$STREAM_URL" 2>&1)
case "$VIDEO" in
    http://*)
    https://*)
        omxplayer -o hdmi "$VIDEO"
        ;;
    *)
        echo "$VIDEO" >&2
        ;;
esac 

sleep infinity
