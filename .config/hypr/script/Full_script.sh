#!/bin/bash

# -----------------------------------------------------
# CONFIG
# -----------------------------------------------------

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
HYPRPAPER_CONF="$HOME/dotfiles/.config/hypr/hyprpaper.conf"

# Detect all monitors dynamically
MONITORS=$(hyprctl monitors -j | jq -r '.[].name')

# -----------------------------------------------------
# 1. SELECT WALLPAPER (wofi)
# -----------------------------------------------------

# List files and use wofi as a menu
SELECTED_FILE=$(ls -1 "$WALLPAPER_DIR" | wofi --show dmenu --prompt "Select Wallpaper" --width 400 --height 500)

if [ -z "$SELECTED_FILE" ]; then
    echo "No wallpaper selected. Exiting."
    exit 0
fi

SELECTED_WALLPAPER="$WALLPAPER_DIR/$SELECTED_FILE"

echo "Selected wallpaper: $SELECTED_WALLPAPER"

# -----------------------------------------------------
# 2. APPLY WALLPAPER (HYPRPAPER)
# -----------------------------------------------------

# Update the hyprpaper.conf file so it persists and is loaded on restart
sed -i "s|^preload = .*|preload = $SELECTED_WALLPAPER|" "$HYPRPAPER_CONF"
sed -i "s|^wallpaper = ,.*|wallpaper = ,$SELECTED_WALLPAPER|" "$HYPRPAPER_CONF"

# Restart hyprpaper to apply the new config reliably
killall hyprpaper
sleep 0.5
nohup hyprpaper > /dev/null 2>&1 &

# -----------------------------------------------------
# 3. GENERATE & APPLY COLOR SCHEME (pywal)
# -----------------------------------------------------

# Generate color scheme and apply to supported terminal apps instantly
wal -i "$SELECTED_WALLPAPER" -n

# Reload waybar to pick up the newly generated colors
if pgrep -x waybar > /dev/null; then
    killall -SIGUSR2 waybar
fi

echo "Wallpaper & colors updated successfully."
