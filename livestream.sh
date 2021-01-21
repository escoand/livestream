#!/bin/sh

splash() {
    if [ -z "${1##*/*}" ]; then
        fbv -cefir "$1" </dev/null
    else
        fbv -cefir "/usr/local/share/splash/$1.jpg" </dev/null
    fi
}

# wifi config
splash check
if ! ping -c1 google.com &>/dev/null; then
    splash nowifi
    wifi-connect
fi

# get stream start
splash stream
echo "load url $STREAM_URL"
NOW=$(date -u +%s)
JSON=$(
    youtube-dl -is --dump-pages "$STREAM_URL" |
    grep -v '^\[' |
    base64 -d |
    sed -n 's#.*var ytInitialPlayerResponse *= *{#{#p' |
    jq -c 2>/dev/null
)
START=$(echo "$JSON" | jq -r '.microformat.playerMicroformatRenderer.liveBroadcastDetails.startTimestamp[:19] + "Z" | fromdate?')
THUMB=$(echo "$JSON" | jq -r '.videoDetails.thumbnail.thumbnails[-1].url')

# wait for start
if [ -n "$START" ] && [ "$START" != null ] && [ "$START" -gt "$NOW" ]; then
    START_STR=$(date +"%d.%m.%Y %H:%M" -d @"$START")
    TMP=$(mktemp)
    curl -sSo "$TMP" "$THUMB" &&
    splash "$TMP" ||
    splash scheduled
    sleep $((START - NOW + 10))
fi

# play stream
youtube-dl -f mp4 -g "$STREAM_URL" |
xargs omxplayer -o hdmi ||
splash error

sleep infinity
