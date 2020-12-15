#!/bin/sh -x

export DBUS_SYSTEM_BUS_ADDRESS=unix:path=/host/run/dbus/system_bus_socket

# disable Network Manager wireless
gdbus call --system \
   --dest org.freedesktop.NetworkManager \
   --object-path /org/freedesktop/NetworkManager \
   --method org.freedesktop.DBus.Properties.Set \
    org.freedesktop.NetworkManager WirelessEnabled '<false>'

# setup wifi
rfkill unblock wlan
ifconfig wlan0 down
ifconfig wlan0 192.168.99.1 netmask 255.255.255.0 up
sleep 5

# start services
# https://github.com/balena-io-playground/access-point-example
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
        echo '<!doctype html>'
        echo '<html>'
        echo '<head>'
        echo '<title>WLAN Konfiguration</title>'
        echo '<meta name="viewport" content="width=device-width, user-scalable=no" />'
        echo '<style>'
        echo 'body{font-family:sans-serif;}'
        echo 'form{left:50%;max-width:250px;top:50%;transform:translate(-50%,-50%);position:absolute;}'
        echo 'label,select,input{display:block;width:100%}'
        echo 'label{font-weight:bold;}'
        echo '</style>'
        echo '</head>'
        echo '<body>'
        echo '<form action="" method="post">'
        echo '<label>Netzwerk:</label>'
        echo '<select name="network">'
        iwlist wlan0 scan | sed -n 's|^.*ESSID:"\([^"]*\)"$|<option>\1</option>|p' | sort -u
        echo '</select>'
        echo '<label>Passwort:</label>'
        echo '<input type="text" name="password" />'
        echo '<input type="submit" value="Absenden" />'
        echo '</form>'
        echo '</body>'
        echo '</html>'
        } |
        nc -l -p 80 |
	tr -d '\r' |
        sed '1,/^$/d' |
        tr '&' '\n'
    )
    SSID=$(echo "$POSTDATA" | grep ^network= | cut -d= -f2-)
    KEY=$(echo "$POSTDATA" | grep ^password= | cut -d= -f2-)

    # config wifi
    if [ -n "$SSID" ] && [ -n "$KEY" ]; then
        UUID=$(cat /proc/sys/kernel/random/uuid)
        DEVICE=$(gdbus call --system \
           --dest org.freedesktop.NetworkManager \
           --object-path /org/freedesktop/NetworkManager \
           --method org.freedesktop.NetworkManager.GetDeviceByIpIface \
           wlan0 | cut -d"'" -f2) &&
        gdbus call --system \
           --dest org.freedesktop.NetworkManager \
           --object-path /org/freedesktop/NetworkManager \
           --method org.freedesktop.NetworkManager.AddAndActivateConnection \
           "{
             '802-11-wireless': {
               'mode': <'infrastructure'>,
               'security': <'802-11-wireless-security'>,
               'ssid': <b'$SSID'>
             },
             '802-11-wireless-security': {
               'auth-alg': <'open'>, 
               'key-mgmt': <'wpa-psk'>,
               'psk': <'$KEY'>
             },
             'connection': {
               'id': <'$SSID'>,
               'type': <'802-11-wireless'>,
               'uuid': <'$UUID'>
             },
             'ipv4': {
               'method': <'auto'>
             },
             'ipv6': {
               'method': <'auto'>
             }
           }" "$DEVICE" "/" &&
        gdbus call --system \
           --dest org.freedesktop.NetworkManager \
           --object-path /org/freedesktop/NetworkManager \
           --method org.freedesktop.DBus.Properties.Set \
            org.freedesktop.NetworkManager WirelessEnabled '<true>' &&
        break
    fi
done

# stop services
kill $PID_HOSTAPD $PID_DNSMASQ
