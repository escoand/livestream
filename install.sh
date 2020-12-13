#!/bin/sh -e

# requirements
grep -q '^http.*/community$' ||
sed -n 's|^\(http.*\)/main$|\1/community|p' /etc/apk/repositories >>/etc/apk/repositories
apk add --no-cache dnsmasq fbida-fbi hostapd imagemagick omxplayer py3-pip ttf-liberation wireless-tools
pip install youtube-dl

# livestream
wget -qO /usr/local/bin/livestream https://raw.githubusercontent.com/escoand/livestream/master/livestream.sh
chmod +x /usr/local/bin/livestream

# splash
wget -qO- https://raw.githubusercontent.com/escoand/livestream/master/splash.sh |
sh -es

# clean
apk del imagemagick ttf-liberation

# persist if installed
if command -v rc-update lbu >/dev/null; then
    cat <<'END' >/etc/init.d/livestream
#!/sbin/openrc-run
command=/usr/local/bin/livestream
command_background=true
pidfile=/run/$RC_SVCNAME/$RC_SVCNAME.pid
END
    chmod +x /etc/init.d/livestream
    rc-update add livestream default
    lbu add /etc/init.d/livestream /usr/local/bin/livestream /usr/local/share/splash/
    lbu commit -d
fi
