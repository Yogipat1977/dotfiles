
#!/bin/bash

# Kill all running waybar processes
pkill -9 waybar

# Small delay to ensure all processes exit
sleep 0.5

# Start a single instance of waybar
waybar &
