#!/bin/bash

# -----------------------------------------------------
# CONFIG
# -----------------------------------------------------

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"

# Detect all monitors dynamically
MONITORS=$(hyprctl monitors -j | jq -r '.[].name')

# -----------------------------------------------------
# 1. SELECT WALLPAPER (nsxiv grid)
# -----------------------------------------------------

SELECTED_WALLPAPER=$(nsxiv -t -o "$WALLPAPER_DIR" | head -n 1)

if [ -z "$SELECTED_WALLPAPER" ]; then
    echo "No wallpaper selected. Exiting."
    exit 0
fi

echo "Selected wallpaper:"
echo "$SELECTED_WALLPAPER"

# -----------------------------------------------------
# 2. APPLY WALLPAPER (NEW HYPRPAPER IPC)
# -----------------------------------------------------

# Remove existing wallpapers
hyprctl hyprpaper unload all

# Apply wallpaper to every monitor
for MONITOR in $MONITORS; do
    hyprctl hyprpaper wallpaper "$MONITOR,$SELECTED_WALLPAPER,cover"
done

# -----------------------------------------------------
# 3. GENERATE COLOR SCHEME (pywal)
# -----------------------------------------------------

wal -i "$SELECTED_WALLPAPER" -n

echo "Wallpaper & colors updated successfully."
