#!/bin/sh

# disable Network Manager wireless
export DBUS_SYSTEM_BUS_ADDRESS=unix:path=/host/run/dbus/system_bus_socket
dbus-send --system --print-reply --dest=org.freedesktop.NetworkManager \
    /org/freedesktop/NetworkManager \
    org.freedesktop.DBus.Properties.Set \
    string:"org.freedesktop.NetworkManager" \
    string:"WirelessEnabled" \
    variant:boolean:false

# setup wifi
rfkill unblock wlan
ifconfig wlan0 down
ifconfig wlan0 192.168.99.1 netmask 255.255.255.0 up
sleep 5

# start services
hostapd /usr/local/etc/hostapd.conf &
PID_HOSTAPD=$!
dnsmasq -dk -C /usr/local/etc/dnsmasq.conf &
PID_DNSMASQ=$!

# portal
while true; do
    POSTDATA=$({
        echo 'HTTP/1.0 200 OK'
        echo 'Connection: close'
        echo
        echo '<html>'
        echo '<head>'
        echo '<title>WLAN Konfiguration</title>'
        echo '</head>'
        echo '<body>'
        echo '<form method="post" action="#">'
        echo '<label>Netzwerk:'
        echo '<select name="network">'
        iwlist wlan0 scan | sed -n 's|^.*ESSID:"\([^"]*\)"$|<option>\1</option>|p' | sort -u
        echo '</select>'
        echo '</label>'
        echo '<label>Passwort:'
        echo '<input type="text" name="password" />'
        echo '</label>'
        echo '<input type="submit" value="Absenden" />'
        echo '</form>'
        echo '</body>'
        echo '</html>'
        } |
        nc -l -p 80 |
        sed '1,/^$/d' |
        tr & '\n'
    )
    SSID=$(echo "$POSTDATA" | grep ^network= | cut -d= -f2-)
    KEY=$(echo "$POSTDATA" | grep ^password= | cut -d= -f2-)

    # config wifi
    if [ -n "$SSID" -a -n "$KEY" ]; then
        iwconfig wlan0 essid "$SSID" key "s:$KEY"
        iwconfig wlan0
        break
    fi
done

# stop services
kill $PID_HOSTAPD $PID_DNSMASQ