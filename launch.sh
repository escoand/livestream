#!/bin/bash

SPLASH_SOCK=/var/run/fbi.sock

# splash chain
rm -f "$SPLASH_SOCK"
mkfifo "$SPLASH_SOCK" &&
tail -f "$SPLASH_SOCK" |
fbi -a -d /dev/fb0 -cachemem 10 -readahead -noverbose /usr/local/share/splash/{boot.png,wifi.jpg,nowifi.jpg,stream.jpg} &
sleep 1

# install boot splash
if [ -b /dev/mmcblk0p1 ]; then
    mount /dev/mmcblk0p1 /mnt/ &&
    cp /usr/local/share/splash/boot.png /mnt/splash/balena-logo.png &&
    umount /dev/mmcblk0p1
fi

# check wifi
printf 1g >> "$SPLASH_SOCK"
iwgetid -r

# wifi config
if [ $? -eq 0 ]; then
    echo 'Skipping WiFi Connect'
else
    echo 'Starting WiFi Connect'
    printf 2g >> "$SPLASH_SOCK"
    wifi-connect
fi

# start stream
printf 3g >> "$SPLASH_SOCK"
python3 /usr/local/bin/youtube-dl -f mp4 -g "$STREAM_URL" |
xargs -r omxplayer -o hdmi

sleep infinity