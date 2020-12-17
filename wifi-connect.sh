#!/bin/sh

export DBUS_SYSTEM_BUS_ADDRESS=unix:path=/host/run/dbus/system_bus_socket

nm_dbus() {
    _PATH="$1"
    _METHOD="$2"
    shift 2
    gdbus call -y -d org.freedesktop.NetworkManager -o "$_PATH" -m "$_METHOD" "$@"
}

# setup wifi
echo "starting access point"
DEVICE=$(nm_dbus /org/freedesktop/NetworkManager org.freedesktop.NetworkManager.GetDeviceByIpIface wlan0 | grep -o "/org/freedesktop/NetworkManager/Devices/[^']*")
SSID_AP=Livestream
UUID_AP=$(cat /proc/sys/kernel/random/uuid)
CONNECTION_AP=$(nm_dbus /org/freedesktop/NetworkManager org.freedesktop.NetworkManager.AddAndActivateConnection \
   "{
     '802-11-wireless': {
       'mode': <'ap'>,
       'ssid': <b'$SSID_AP'>
     },
     'connection': {
       'id': <'$SSID_AP'>,
       'type': <'802-11-wireless'>,
       'uuid': <'$UUID_AP'>
     },
     'ipv4': {
       'method': <'manual'>,
       'address-data': <[{
         'address': <'192.168.99.1'>,
         'prefix': <@u 24>
       }]>
     }
   }" "$DEVICE" "/" | grep -o "/org/freedesktop/NetworkManager/Settings/[^']*")
sleep 3
echo "access point started"

# start services
echo "start DNS server"
dnsmasq -dk -C /usr/local/etc/dnsmasq.conf &
PID_DNSMASQ=$!

# clean up on exit
trap "kill $PID_DNSMASQ; nm_dbus $CONNECTION_AP org.freedesktop.NetworkManager.Settings.Connection.Delete; exit 0" EXIT
trap "kill $PID_DNSMASQ; nm_dbus $CONNECTION_AP org.freedesktop.NetworkManager.Settings.Connection.Delete; exit 1" SIGTERM

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
        iwlist wlan0 scan |
        sed -n 's|.* ESSID:"\([^"]*\)".*|<option>\1</option>|p' |
        sort -u
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
        sed '1,/^$/d; y/+/ /; s/%/\\\\x/g' |
        tr '&' '\n' |
        xargs -ri echo -e '{}'
    )
    SSID=$(echo "$POSTDATA" | grep ^network= | cut -d= -f2-)
    KEY=$(echo "$POSTDATA" | grep ^password= | cut -d= -f2-)

    # config wifi
    if [ -n "$SSID" ] && [ -n "$KEY" ]; then
        echo "try to connect to <$SSID>"

        # create new
        UUID=$(cat /proc/sys/kernel/random/uuid)
        BYTES=$(printf '%s' "$SSID" | od -An -tx1 | sed -n 'H; ${g;s/[\n ]\{1,\}/,0x/g;s/^,//;p}')
        CONNECTION=$(nm_dbus /org/freedesktop/NetworkManager/Settings org.freedesktop.NetworkManager.Settings.AddConnection \
            "{
              '802-11-wireless': {
                'hidden': <true>,
                'mode': <'infrastructure'>,
                'security': <'802-11-wireless-security'>,
                'ssid': <[byte $BYTES]>
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
            }" | grep -o "/org/freedesktop/NetworkManager/Settings/[^']*")

        # activate new
        ACTIVE=$(nm_dbus /org/freedesktop/NetworkManager org.freedesktop.NetworkManager.ActivateConnection \
            "$CONNECTION" "$DEVICE" "/" | grep -o "/org/freedesktop/NetworkManager/[^']*")
        while gdbus introspect -y -d org.freedesktop.NetworkManager -p -o "$ACTIVE" | grep -q ' State = [01];'; do
            sleep 1
            echo "still connecting"
        done

        # successful
        if gdbus introspect -y -d org.freedesktop.NetworkManager -p -o "$ACTIVE" | grep -q ' State = 2;'; then
            echo "connect successful"
            break

        # next try
        else
            nm_dbus "$CONNECTION" org.freedesktop.NetworkManager.Settings.Connection.Delete
            echo "connect failed"
        fi
    fi
done
