#!/bin/sh

splash() {
    fbv -cefir "/usr/local/share/splash/$1.jpg" </dev/null
}

set -E
trap "splash error; sleep 10; exit 1" ERR

# wifi config
splash check
if ! ping -c1 google.com &>/dev/null; then
    splash nowifi
    wifi-connect
fi

# start stream
splash stream
echo "load url $STREAM_URL"
VIDEO=$(youtube-dl -f mp4 -g "$STREAM_URL" 2>&1)
echo "result was $VIDEO"
case "$VIDEO" in
    http*)
        omxplayer -o hdmi "$VIDEO"
        ;;
    *)
        echo "$VIDEO" >/dev/tty2
        ;;
esac 

sleep infinity
