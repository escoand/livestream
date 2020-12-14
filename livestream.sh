#!/bin/sh -x

# default config https://github.com/balena-io-playground/access-point-example

splash() {
    fbv -cefir "/usr/local/share/splash/$1.jpg" </dev/null
}

# wifi config
splash check
if ! iwgetid -r; then
    splash nowifi
    ifconfig wlan0 192.168.99.1 netmask 255.255.255.0 up
    sleep 5
    hostapd /usr/local/etc/hostapd.conf &
    PID_HOSTAPD=$!
    dnsmasq -dk -C /usr/local/etc/dnsmasq.conf &
    PID_DNSMASQ=$!
    ( while true; do portal | nc -l -p 80; done ) &
    PID_PORTAL=$!
    sleep 600
    kill $PID_HOSTAPD $PID_DNSMASQ $PID_PORTAL
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
