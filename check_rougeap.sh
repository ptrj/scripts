#!/bin/bash

# Define your WiFi interface
WIFI_DEV=wlan0

## Assign your Mac address to WiFi name
#
# Example: sudo iwlist wlan0 scanning | less -S
#          find for your ESSID and Address
#
# One AP on 2.4GHz
# declare -A MY_ESSID=( ["C0:4A:00:53:A7:48"]="MyWiFi" )
#
# One AP on 2.4Ghz & 5GHz
# declare -A MY_ESSID=( ["C0:4A:00:53:A7:48"]="MyWiFi" \
#                       ["C0:4A:00:53:A7:49"]="MyWiFi" )
#
# Two APs on 2.4Ghz & 5GHz
# declare -A MY_ESSID=(
#                       ["3C:CE:73:8F:6D:92"]="MyWiFi" \
#                       ["3C:CE:73:8F:6D:93"]="MyWiFi" \
#                       ["C8:3A:35:FC:60:68"]="GuestWiFi" \
#                       ["C8:3A:35:FC:60:69"]="GuestWiFi" \
#                  )

declare -A MY_ESSID=( ["5F:90:A9:16:5E:52"]="MyHome" ["5F:90:A9:16:5E:53"]="MyHome" \
                      ["CC:D5:AF:9A:D9:5D"]="MyGuest" ["CC:D5:AF:9A:D9:5D"]="MyGuest" )

# check if iwlist exist
IWL="$(which iwlist)"
if [ -z $IWL ]; then
  echo "You need to install wireless_tools package. Can't find iwlist command"
  exit 1
fi
# iwlist needs to be run as root user
if [ ! $(id -u) -eq 0 ]; then
  echo "Use sudo or run script as root user"
  exit 1
fi

SEND_ALERT() {
  # Make your own notification, example Telegram
  # http://www.home-automation-community.com/telegram-messenger-on-the-raspberry-pi/
  # https://github.com/vysheng/tg
  # https://pimylifeup.com/raspberry-pi-telegram-cli/
  # https://pimylifeup.com/raspberry-pi-telegram-bot/
  echo "!! ALERT !!"
}

UNIQUE_ESSID=($(echo ${MY_ESSID[@]} | tr ' ' '\n' | sort -u))
for ID in ${UNIQUE_ESSID[@]}; do
  echo "# $ID"
  SCAN_MACADDRS=($(sudo ${IWL} ${WIFI_DEV} scanning | grep -B5 ${ID} | grep -o "Address:.*" | cut -d" " -f2))
  for MAC in ${SCAN_MACADDRS[@]}; do
    echo $MAC $(if [[ -z ${MY_ESSID[$MAC]} ]]; then echo "Rogue AP Detected!"; SEND_ALERT; else echo "OK"; fi)
  done
done
