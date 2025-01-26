#!/bin/sh
function findSurroundingDevicesAndDistance () { sudo iw dev wlx0013eff5483f scan | egrep "signal:|SSID:" | sed -e "s/\tsignal: //" -e "s/\tSSID: //" | awk '{ORS = (NR % 2 == 0)? "\n" : " "; print}' | sort }
echo"hi"
findSurroundingDevicesAndDistance
echo "bye "
