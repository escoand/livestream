#!/bin/sh

splash() {
    fbv -cefir "/usr/local/share/splash/$1.jpg" </dev/null
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
NOW=$(date -u +%Y-%m-%dT%H:%M:%S+00:00)
START=$(
    youtube-dl -is --dump-pages "$STREAM_URL" |
    grep -v '^\[' |
    base64 -d |
    sed -n 's#.*var ytInitialPlayerResponse *= *\({.*\)#\1#p' |
    jq -r '.microformat.playerMicroformatRenderer.liveBroadcastDetails.startTimestamp'
) 2>/dev/null

# wait for start
if [ -n "$START" ] && [ "$START" != null ] && [ "$START" < "$NOW" ]; then
    splash scheduled
    TS_NOW=$(date +%s)
    TS_START=$(date +%s -d "$START")
    sleep $(($TS_START - $TS_NOW + 10))
fi

# play stream
youtube-dl -f mp4 -g "$STREAM_URL" |
omxplayer -o hdmi "$VIDEO" ||
splash error

sleep infinity
