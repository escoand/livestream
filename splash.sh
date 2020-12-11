#!/bin/sh

SPLASH_URL="https://unsplash.com/photos/19iL-6uC5C4/download?force=true"
STROKE_COLOR=none
FILL_COLOR=white
DIMENSIONS=1920x1080

# download image
curl -Ls "$SPLASH_URL" -o /tmp/splash.tmp &&

# create splash images
mkdir -p /tmp/output &&
cat <<'END' |
boot	Anwendung wird gestartet
wifi	Internetverbindung wird getestet
nowifi	Bitte zum W-Lan "WIFI Connect" verbinden und Zugangsdaten eingeben
stream	Video wird geladen
END
while read -r NAME TEXT; do
	convert /tmp/splash.tmp \
		-resize "$DIMENSIONS^" \
		-gravity center \
		-crop "$DIMENSIONS+0+0" \
		+repage \
		-background none \
		-fill "$FILL_COLOR" \
		-gravity south \
		-pointsize 40 \
		-stroke "$STROKE_COLOR" \
		-annotate +0+40 "$TEXT" \
		"/tmp/output/splash-$NAME.png"
done