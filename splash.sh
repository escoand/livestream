#!/bin/sh

SPLASH_URL="https://unsplash.com/photos/19iL-6uC5C4/download?force=true"
STROKE_COLOR=none
FILL_COLOR=white
FONT=Liberation-Sans
DIMENSIONS=1280x720

# download image
curl -Ls "$SPLASH_URL" -o /tmp/splash.tmp &&

# create splash images
mkdir -p /tmp/splash &&
cat <<'END' |
boot	png	Anwendung wird gestartet
wifi	jpg	Internetverbindung wird getestet
nowifi	jpg	Bitte zum W-Lan "WIFI Connect" verbinden und Zugangsdaten eingeben
stream	jpg	Video wird geladen
END
while read -r NAME EXTENSION TEXT; do
	convert /tmp/splash.tmp \
		-resize "$DIMENSIONS^" \
		-gravity center \
		-crop "$DIMENSIONS+0+0" \
		+repage \
		-background none \
		-fill "$FILL_COLOR" \
		-font "$FONT" \
		-gravity south \
		-pointsize 40 \
		-stroke "$STROKE_COLOR" \
		-annotate +0+40 "$TEXT" \
		-strip \
		"/tmp/splash/$NAME.$EXTENSION"
done
