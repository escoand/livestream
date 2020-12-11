#!/bin/sh

# check wifi
iwgetid -r
if [ $? -eq 0 ]; then
    printf 'Skipping WiFi Connect\n'
else
    printf 'Starting WiFi Connect\n'
    wifi-connect
fi

# start stream
python3 /usr/local/bin/youtube-dl -f mp4 -g "$STREAM_URL" |
xargs -tr omxplayer -o hdmi