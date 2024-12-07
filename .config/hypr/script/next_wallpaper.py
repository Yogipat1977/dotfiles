#!/usr/bin/python3

import glob
import subprocess

folder_path = '/home/yogipatel/Pictures/Wallpapers/'

def get_current_wallpaper() -> str:
    output = subprocess.run(['current_wal'], stdout=subprocess.PIPE, stderr=subprocess.PIPE)

    return output.stdout.decode().strip()

def get_next_wallpaper(current_wallpaper:str, files:list[str]) -> str:
    for index,file in enumerate(files):
        if file == current_wallpaper:
            try:
                return files[index+1]
            except:
                # print('next file does not exist, restarting the loop')
                return files[0]
    

current_wallpaper = get_current_wallpaper()

files = glob.glob(folder_path+'*')

next_wallpaper = get_next_wallpaper(current_wallpaper,files)
print(next_wallpaper)
