#!/bin/sh -x

# check wifi
iwgetid -r
if [ $? -eq 0 ]; then
    printf 'Skipping WiFi Connect\n'
else
    printf 'Starting WiFi Connect\n'
    /usr/local/bin/wifi-connect
fi

# start stream
VIDEO_URL=$(youtube-dl -g "$STREAM_URL")
omxplayer "$VIDEO_URL"