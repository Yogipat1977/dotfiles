#!/bin/bash

# Directory containing wallpapers
WALLPAPER_DIR="/home/yogipatel/Pictures/Wallpapers"

# Hyprpaper config file
CONFIG_FILE="/home/yogipatel/dotfiles/.config/hypr/hyprpaper.conf"

# Select a random wallpaper
RANDOM_WALLPAPER=$(find "$WALLPAPER_DIR" -type f | shuf -n 1)

# Escape special characters in the wallpaper path for sed
RANDOM_WALLPAPER_ESCAPED=$(printf '%s\n' "$RANDOM_WALLPAPER" | sed 's/[&/\\]/\\&/g')

# Ensure the preload line exists or update it
if grep -q "^preload = " "$CONFIG_FILE"; then
    sed -i "/^preload = /c\preload = $RANDOM_WALLPAPER_ESCAPED" "$CONFIG_FILE"
else
    echo "preload = $RANDOM_WALLPAPER" >> "$CONFIG_FILE"
fi

# Update the wallpaper line with the new wallpaper path, keeping the comma
if grep -q "^wallpaper = " "$CONFIG_FILE"; then
    sed -i "/^wallpaper = /c\wallpaper = ,$RANDOM_WALLPAPER_ESCAPED" "$CONFIG_FILE"
else
    echo "wallpaper = ,$RANDOM_WALLPAPER" >> "$CONFIG_FILE"
fi

# Restart Hyprpaper to apply the changes
pkill -USR1 hyprpaper
pkill hyprpaper
hyprpaper &

# Wait for Hyprpaper to fully restart (optional: adjust delay if needed)
sleep 1

# Extract the first currently active wallpaper path from the Hyprpaper status
ACTIVE_WALLPAPER=$(hyprctl hyprpaper listactive | grep '=' | head -n 1 | cut -d '=' -f2 | xargs)

# Check if a valid path was extracted
if [ -z "$ACTIVE_WALLPAPER" ]; then
  echo "Error: Could not determine the active wallpaper path."
  exit 1
fi

# Generate the colorscheme using wal
wal -i "$ACTIVE_WALLPAPER" -n

# Reload Hyprpaper with the updated wallpaper and colorscheme
hyprctl hyprpaper unload all
echo "Updated colorscheme for $ACTIVE_WALLPAPER"
