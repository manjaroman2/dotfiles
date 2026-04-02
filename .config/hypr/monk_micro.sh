#!/usr/bin/env bash

read -r CURRENT_X CURRENT_Y < <(hyprctl cursorpos | tr ',' ' ')

evtest --grab /dev/input/event2 > /dev/null 2>&1 &
GRAB_PID=$!

ydotool --chain \
  key -d 0 16:1 16:0 \
  click -D 0 0xC1
hyprctl dispatch movecursor 380 1270
ydotool --chain \
  mousemove -x 1 -y 0 \
  mousemove -x -1 -y 0 \
  key -d 0 29:1 \
  click -D 0 0xC0 \
  key -d 0 29:0
hyprctl dispatch movecursor "$CURRENT_X" "$CURRENT_Y"
ydotool --chain \
  mousemove -x 1 -y 0 \
  mousemove -x -1 -y 0

kill "$GRAB_PID"

#  gamescope -s 0.1 --force-grab-cursor -w 2560 -h 1440 --
