#!/bin/sh -x

splash() {
    fbv -cefir "/usr/local/share/splash/$1.jpg" </dev/null
}

# wifi config
splash check
if ! iwgetid -r; then
    splash nowifi
    ifconfig wlan0 192.168.99.1 netmask 255.255.255.0 up
    sleep 5
    hostapd -B /usr/local/etc/hostapd.conf
    dnsmasq -C /usr/local/etc/dnsmasq.conf -d
    sleep 120
fi

# start stream
splash stream
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
