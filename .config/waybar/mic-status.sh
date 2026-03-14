#!/bin/bash
# Microphone mute status for Waybar
# Automatically uses the default mic

# Get the default microphone
MIC=$(pactl get-default-source 2>/dev/null)

# Get mute status
STATUS=$(pactl get-source-mute "$MIC" 2>/dev/null | awk '{print $2}')  # prints "yes" or "no"


# Get a friendly mic name
MIC_NAME=$(pactl list sources | grep -A 5 "$MIC" | grep "Description:" | sed 's/^[[:space:]]*Description: //')

# Output JSON for Waybar
if [ "$STATUS" = "yes" ]; then
    echo "{\"text\": \"󰍭\", \"tooltip\": \"Microphone: Muted ($MIC_NAME)\", \"class\": \"muted\"}"
else
    echo "{\"text\": \"󰍬\", \"tooltip\": \"Microphone: Active ($MIC_NAME)\", \"class\": \"active\"}"
fi
