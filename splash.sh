#!/bin/sh -e

SPLASH_URL=${SPLASH_URL:-https://unsplash.com/photos/EOQhsfFBhRk/download?force=true}
STROKE_COLOR=none
FILL_COLOR=white
FONT=Liberation-Sans
DIMENSIONS=1280x720
TMP=$(mktemp)
DSTDIR=/usr/local/share/splash

# download image
wget -qO "$TMP" "$SPLASH_URL" &&

# create splash images
mkdir -p "$DSTDIR" &&
cat <<'END' |
boot		png	Anwendung wird gestartet
check		jpg	Internetverbindung wird getestet
nowifi		jpg	Zum WLAN "Livestream" verbinden und Zugangsdaten eingeben
scheduled	jpg	Live am
stream		jpg	Video wird geladen
error		jpg	Leider gab es einen Fehler
END
while read -r NAME EXTENSION TEXT; do
	convert "$TMP" \
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
		"$DSTDIR/$NAME.$EXTENSION"
done

rm -f "$TMP"
