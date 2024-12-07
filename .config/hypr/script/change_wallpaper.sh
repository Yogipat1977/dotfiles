#!/bin/bash

# Paths
WALLPAPER_DIR="$HOME/Pictures/Wallpapers"  # Path to your wallpaper folder
HYPRPAPER_CONF="$HOME/.config/hypr/hyprpaper.conf"  # Path to your hyprpaper.conf

# Function to set a new random wallpaper
set_random_wallpaper() {
    # Select a random wallpaper
    WALLPAPER=$(find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.png" \) | shuf -n 1)
    
    if [ -z "$WALLPAPER" ]; then
        echo "No wallpapers found in $WALLPAPER_DIR"
        exit 1
    fi

    # Update the hyprpaper.conf file with the new wallpaper
    sed -i "s|^wallpaper =.*,|wallpaper = ,$WALLPAPER|" "$HYPRPAPER_CONF"

    echo "Set wallpaper to: $WALLPAPER"

    # Reload HyprPaper
    pkill -USR1 hyprpaper
}

# Run the function
set_random_wallpaper
