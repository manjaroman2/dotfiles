#!/bin/bash
PCTL=/usr/bin/pactl
NOTIFY=/usr/bin/notify-send
PKILL=/usr/bin/pkill

SRC=$($PCTL get-default-source 2>/dev/null)

$PCTL set-source-mute "$SRC" toggle

STATUS=$($PCTL get-source-mute "$SRC" | awk '{print $1}')  # yes/no

if [ "$STATUS" = "yes" ]; then
    $NOTIFY "Mic muted" "$SRC"
else
    $NOTIFY "Mic unmuted" "$SRC"
fi

$PKILL -RTMIN+10 waybar

