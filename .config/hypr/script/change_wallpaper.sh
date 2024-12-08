#!/bin/bash

# Directory containing wallpapers
WALLPAPER_DIR="/home/yogipatel/Pictures/Wallpapers"

# Hyprpaper config file
CONFIG_FILE="/home/yogipatel/dotfiles/.config/hypr/hyprpaper.conf"

# Select a random wallpaper
RANDOM_WALLPAPER=$(find "$WALLPAPER_DIR" -type f | shuf -n 1)

# Update the preload line with the new wallpaper path
sed -i "/^preload = /c\preload = $RANDOM_WALLPAPER" "$CONFIG_FILE"

# Update the wallpaper line with the new wallpaper path, keeping the comma
sed -i "/^wallpaper = /c\wallpaper = ,$RANDOM_WALLPAPER" "$CONFIG_FILE"

# Restart Hyprpaper to apply the changes
pkill -USR1 hyprpaper
pkill hyprpaper
hyprpaper &
