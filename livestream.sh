#!/bin/sh -e

SPLASH_SOCK=/run/livestream/fbi.sock
SPLASH_DIR=/usr/local/share/splash

# wifi config
fbv "$SPLASH_DIR/check.jpg"
echo >> "$SPLASH_SOCK"
if iwgetid -r; then
    echo 'Skipping WiFi Connect'
else
    fbv "$SPLASH_DIR/wifi.jpg"
    echo 'Starting WiFi Connect'
    wifi-connect
fi

# start stream
fbv "$SPLASH_DIR/stream.jpg"
VIDEO=$(youtube-dl -f mp4 -g "$STREAM_URL" 2>&1)
case "$VIDEO" in
    http*)
        omxplayer -o hdmi "$VIDEO"
        ;;
    *)
        echo "$VIDEO" >&2
        ;;
esac 

sleep infinity
