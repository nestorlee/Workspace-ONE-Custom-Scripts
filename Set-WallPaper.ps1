#***************************************************************************************************************************#
# Project                   : Windows 10 Wallpaper Change w/o Restart                                                       #
#                                                                                                                           #
# Program name              : Set-WallPaper.ps1                                                                             #
#                                                                                                                           #
# Author                    : Nestor Lee                                                                                    #           
#                                                                                                                           #
# Date created (DDMMYYYY)   : 09022021                                                                                      #
#                                                                                                                           #
# Purpose                   : Done up to perform an automated wallpaper change on a Windows 10 device without a restart     #                                                                                      
#                                                                                                                           #
# Revision History          :                                                                                               #
#                                                                                                                           #
# Date (DDMMYYYY)       Author              Ref     Revision (Date in DDMMYYYY format)                                      #
# 09022021              Nestor Lee          1       First version - 09022021                                                #
#                                                                                                                           #
#***************************************************************************************************************************#        

$wallpaperPath = "C:\Temp\vmware_wallpaper.jpg"

while(1){
    if([System.IO.File]::Exists($wallpaperPath)){
        break
    }
    Write-Output "WallPaper Image not found. Will not continue."
    Start-Sleep 5
}

Set-ItemProperty -path 'HKCU:\Control Panel\Desktop\' -name Wallpaper -value $wallpaperPath
Set-ItemProperty -path 'HKCU:\Control Panel\Desktop\' -name TileWallpaper -value "0"
Set-ItemProperty -path 'HKCU:\Control Panel\Desktop\' -name WallpaperStyle -value "10" -Force

for($i=1; $i -le 5; $i++){
    RUNDLL32.EXE USER32.DLL,UpdatePerUserSystemParameters ,1 ,True
}