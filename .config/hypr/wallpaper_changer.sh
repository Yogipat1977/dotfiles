#!/bin/bash

# Paths
WALLPAPER_DIR="/home/yogipatel/Pictures/Wallpapers/"  # Path to your wallpaper folder
HYPRPAPER_CONF="/home/yogipatel/dotfiles/.config/hypr/hyprpaper.conf"  # Path to hyprpaper.conf
HYPRLAND_CONF="/home/yogipatel/dotfiles/.config/hypr/hyprland.conf"  # Path to Hyprland config

# Function to set a new random wallpaper
set_random_wallpaper() {
    # Select a random wallpaper
    WALLPAPER=$(find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.png" \) | shuf -n 1)
    
    if [ -z "$WALLPAPER" ]; then
        echo "No wallpapers found in $WALLPAPER_DIR"
        exit 1
    fi

    # Update hyprpaper.conf
    echo "wallpaper=$WALLPAPER" > "$HYPRPAPER_CONF"
    echo "Set wallpaper to: $WALLPAPER"

    # Reload HyprPaper
    pkill -USR1 hyprpaper
}

# Set the initial random wallpaper
set_random_wallpaper

# Check if a keybind is already in Hyprland config
if ! grep -q "bind=SUPER,space,exec /home/yogipatel/dotfiles/.config/hypr/wallpaper_changer.sh" "$HYPRLAND_CONF"; then
    # Add keybind for changing wallpaper
    echo "bind=SUPER,space,exec /home/yogipatel/dotfiles/.config/hypr/wallpaper_changer.sh" " >> "$HYPRLAND_CONF"
    echo "Added keybind: SUPER + Space to change wallpaper"
fi
