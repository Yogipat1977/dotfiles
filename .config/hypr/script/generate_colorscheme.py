#!/usr/bin/python3

import subprocess


output = subprocess.run(['hyprctl','hyprpaper','listactive'], stdout=subprocess.PIPE)


# output,err = active_wallpaper_process.communicate()


path = output.stdout.decode().split('=')[1].strip()
generate_colorscheme_process = subprocess.run(f"wal -i {path} -n", shell=True,stdout=subprocess.PIPE)
subprocess.run(f"hyprctl hyprpaper unload all", shell=True)
print('Updated colorscheme for', path)