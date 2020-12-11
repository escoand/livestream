#!/bin/sh

splash() {
    fbi -a -d /dev/fb0 -noverbose "/usr/local/share/splash/$1.jpg" </dev/null
}

# install boot splash
if [ -b /dev/mmcblk0p1 ]; then
    mount /dev/mmcblk0p1 /mnt/ &&
    cp /usr/local/share/splash/boot.png /mnt/splash/balena-logo.png &&
    umount /dev/mmcblk0p1
fi

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
