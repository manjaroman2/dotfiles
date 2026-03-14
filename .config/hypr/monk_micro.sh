#!/usr/bin/env bash
TARGET_X=4147
TARGET_Y=14122

CURRENT=$(hyprctl cursorpos)
CUR_X=${CURRENT%%,*}
CUR_X=${CUR_X// /}
CUR_Y=${CURRENT##*,}
CUR_Y=${CUR_Y// /}

CUR_YD_X=$(( CUR_X * 111199 / 10000 ))
CUR_YD_Y=$(( CUR_Y * 111199 / 10000 ))

evtest --grab /dev/input/event2 > /dev/null 2>&1 &
GRAB_PID=$!
~/dev/ydotool/build/ydotool --chain \
  mousemove --absolute -- "$TARGET_X" "$TARGET_Y" \
  key -d 0 29:1 \
  click -D 0 0xC0
kill $GRAB_PID
 ~/dev/ydotool/build/ydotool --chain \
  key -d 0 29:0 \
  mousemove --absolute -- "$CUR_YD_X" "$CUR_YD_Y" \
  key -d 0 16:1 16:0 \
  click -D 0 0xC1
