#!/bin/sh -x

splash() {
    fbv -cefir "/usr/local/share/splash/$1.jpg" </dev/null
}

# wifi config
splash check
if ! ping -c1 google.com &>/dev/null; then
    splash nowifi
    wifi-connect
fi

# start stream
splash stream
VIDEO=$(youtube-dl -f mp4 -g "$STREAM_URL" 2>&1)
case "$VIDEO" in
    http*)
        omxplayer -o hdmi "$VIDEO"
        ;;
    *)
        echo "$VIDEO" >/dev/tty2
        ;;
esac 

sleep infinity
