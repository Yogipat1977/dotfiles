#!/bin/bash

# Check if Waybar is running
if pgrep -x waybar > /dev/null; then
    # If Waybar is running, kill it
    killall -q waybar
    echo "Waybar has been stopped."
else
    # If Waybar is not running, start it
    waybar &
    echo "Waybar has been started."
fi

