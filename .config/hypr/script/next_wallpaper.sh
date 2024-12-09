#!/bin/bash

# Function to change the wallpaper
change_wallpaper() {
    # Path to wallpapers directory
    wallpapers_dir="/home/yogipatel/Pictures/Wallpapers"
    # Randomly select a wallpaper
    new_wallpaper=$(find "$wallpapers_dir" -type f | shuf -n 1)

    # Set the wallpaper using hyprpaper
    echo "wallpaper=$new_wallpaper" > ~/.config/hypr/hyprpaper.conf
    hyprctl hyprpaper unload all
    hyprctl hyprpaper reload
    echo "Wallpaper changed to $new_wallpaper"

    echo "$new_wallpaper"
}

# Function to generate colorscheme
generate_colorscheme() {
    wallpaper_path="$1"
    # Generate colorscheme using `wal`
    wal -i "$wallpaper_path" -n
    hyprctl hyprpaper unload all
    echo "Updated colorscheme for $wallpaper_path"
}

# Main execution
new_wallpaper=$(change_wallpaper)
generate_colorscheme "$new_wallpaper"
