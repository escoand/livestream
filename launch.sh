#!/bin/sh

SPLASH_SOCK=/var/run/fbi.sock
SPLASH_DIR=/usr/local/share/splash

# splash chain
rm -f "$SPLASH_SOCK"
mkfifo "$SPLASH_SOCK" &&
tail -f "$SPLASH_SOCK" |
fbi -a -d /dev/fb0 -cachemem 10 -readahead -noverbose \
    "$SPLASH_DIR/check.jpg" \
    "$SPLASH_DIR/nowifi.jpg" \
    "$SPLASH_DIR/stream.jpg" &
sleep 1

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
