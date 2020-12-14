#!/bin/sh

# disable Network Manager wireless
export DBUS_SYSTEM_BUS_ADDRESS=unix:path=/host/run/dbus/system_bus_socket
dbus-send --system --print-reply --dest=org.freedesktop.NetworkManager /org/freedesktop/NetworkManager org.freedesktop.DBus.Properties.Set string:"org.freedesktop.NetworkManager" string:"WirelessEnabled" variant:boolean:false

# setup wifi
rfkill unblock wlan
ifconfig wlan0 down
ifconfig wlan0 192.168.99.1 netmask 255.255.255.0 up
sleep 5

# start process
hostapd /usr/local/etc/hostapd.conf &
PID_HOSTAPD=$!
dnsmasq -dk -C /usr/local/etc/dnsmasq.conf &
PID_DNSMASQ=$!

# portal
while true; do
    {
    cat <<'END'
HTTP/1.0 200 OK
Connection: close

<html>
<head>
<title>WLAN Konfiguration</title>
</head>
<body>
<form method="post" action="#">
<label>Netzwerk:
<select name="network">
END
    iwlist wlan0 scan | sed -n 's|^.*ESSID:"\([^"]*\)"$|<option>\1</option>|p' | sort -u
    cat <<'END'
</select>
</label>
<label>Passwort:
<input type="text" name="password" />
</label>
<input type="submit" name="Absenden" />
</form>
</body>
</html>
END
    } | nc -l -p 80
done

kill $PID_HOSTAPD $PID_DNSMASQ