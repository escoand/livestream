#!/bin/sh -x

splash() {
    fbv -cefir "/usr/local/share/splash/$1.jpg" </dev/null
}

# wifi config
splash check
if iwgetid -r; then
    echo 'Skipping WiFi Connect'
else
    splash nowifi
    echo 'Starting WiFi Connect'
    # default config https://github.com/balena-io-playground/access-point-example
    hostapd /usr/local/etc/hostapd.conf &
    PID_HOSTAPD=$!
    dnsmasq -C /usr/local/etc/dnsmasq.conf -d -k &
    PID_DNSMASQ=$!
    sleep 120
    kill $PID_HOSTAPD $PID_DNSMASQ
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
