#!/bin/sh

splash() {
    fbi -a -d /dev/fb0 "/usr/local/share/splash/splash-$1.jpg" </dev/null
}

# check wifi
splash wifi
iwgetid -r

# wifi config
if [ $? -eq 0 ]; then
    printf 'Skipping WiFi Connect\n'
else
    printf 'Starting WiFi Connect\n'
    splash nowifi
    wifi-connect
fi

# start stream
splash stream
python3 /usr/local/bin/youtube-dl -f mp4 -g "$STREAM_URL" |
xargs -tr omxplayer -o hdmi
