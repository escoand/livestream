#!/bin/sh

# check wifi
fbi -a -d /dev/fb0 /usr/local/share/splash/splash-wifi.jpg </dev/null
iwgetid -r

# wifi config
if [ $? -eq 0 ]; then
    printf 'Skipping WiFi Connect\n'
else
    printf 'Starting WiFi Connect\n'
    fbi -a -d /dev/fb0 /usr/local/share/splash/splash-nowifi.jpg </dev/null
    wifi-connect
fi

# start stream
fbi -a -d /dev/fb0 /usr/local/share/splash/splash-stream.jpg </dev/null
python3 /usr/local/bin/youtube-dl -f mp4 -g "$STREAM_URL" |
xargs -tr omxplayer -o hdmi