#!/bin/sh -e

# requirements
grep -q '^http.*/community$' ||
sed -n 's|^\(http.*\)/main$|\1/community|p' /etc/apk/repositories >>/etc/apk/repositories
apk add --no-cache gcc git libjpeg-turbo-dev libpng-dev ttf-liberation

# livestream
wget -qO /usr/local/bin/livestream https://raw.githubusercontent.com/escoand/livestream/master/livestream.sh
chmod +x /usr/local/bin/livestream

# splash
wget -qO- https://raw.githubusercontent.com/escoand/livestream/master/splash.sh |
sh -es

# fbv
git clone https://github.com/godspeed1989/fbv.git
cd fbv
./configure
make
cp fbv /usr/local/bin/

# clean
apk del gcc git imagemagick libjpeg-turbo-dev libpng-dev ttf-liberation
apk add --no-cache dnsmasq hostapd libjpeg-turbo libpng omxplayer py3-pip wireless-tools
pip install youtube-dl

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
    lbu add /etc/init.d/livestream /usr/local/bin/ /usr/local/share/splash/
    lbu commit -d
fi
