#! /bin/sh
PARENT_PATH=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
cd "$PARENT_PATH"
if [ -f .env ]
then
  export $(cat .env | xargs)
fi

# TODO: make sure I'm connected via ADB
# TODO: adb tcpip 5555
# TODO: Restart machine hourly
# TODO: Make sure I have a network connection, if not try to connect using credentials stored on the frame

LOG=""
log ()
{
	echo "$1"
	LOG=$LOG\\n"$1"
	# TODO: log to log file!
}

ADB="adb shell"

log "-----------------------------------------"

DATE=$($ADB date +%s | tr -d '\r')
log "DATE: $DATE"

PINGRESULT=$($ADB ping -c 1 google.com | tr -d '\n' | tr -d '\r')
log "PINGRESULT: $PINGRESULT"

PINGERROR=$?
log "PINGERROR: $PINGERROR"

if [ $PINGERROR -eq 0 ]; then
	NETWORK_STATUS="connected"
else
	NETWORK_STATUS="disconnected"
fi
log "NETWORK_STATUS: $NETWORK_STATUS"

WIFI_SSID=$($ADB su 0 cat /data/misc/wifi/wpa_supplicant.conf | grep ssid | cut -d "\"" -f 2 | tr -d '\r')
log "WIFI_SSID: $WIFI_SSID"

WIFI_PASSWORD=$($ADB su 0 cat /data/misc/wifi/wpa_supplicant.conf | grep psk | cut -d "\"" -f 2 | tr -d '\r')
log "WIFI_PASSWORD: $WIFI_PASSWORD"

if [ $PINGERROR -ne 0 ]; then
	grep "$WIFI_SSID" /etc/wpa_supplicant/wpa_supplicant.conf
	WIFI_EXISTS=$?
	if [ $WIFI_EXISTS -ne 0 ]; then
		# Scrape wifi ssid and password and set it up.
		log "Adding new wireless network to config and resetting the config, cc @drew"
		wpa_passphrase "$WIFI_SSID" "$WIFI_PASSWORD" | tee -a /etc/wpa_supplicant/wpa_supplicant.conf
		wpa_cli reconfigure
		# Sleep a minute to maybe have the curl below work.
		sleep 60
	else
		log "No network connection but the wifi appears to be configured properly. Weird! cc @drew"
	fi
fi

# Start collecting data to upload
# get ip
IP_COMMAND="ip -4 a show wlan0 | grep -o -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -1"
IP="$($ADB $IP_COMMAND | tr -d '\r')"
log "IP: $IP"

CONTROLLER_IP=$(hostname -I | cut -d " " -f 1)
log "CONTROLLER IP: $CONTROLLER_IP"

FREESPACE=$($ADB df /data | tr -s " " | cut -d " " -f 4 | tail -n -1 | tr -d '\r')
log "FREESPACE: $FREESPACE"

USEDSPACE=$($ADB df /data | tr -s " " | cut -d " " -f 3 | tail -n -1 | tr -d '\r')
log "USEDSPACE: $USEDSPACE"

PERCENTSPACE=$($ADB su 0 toybox df /data | tail -n 1 | tr -s " " | cut -d " " -f 5 | tr -d "%" | tr -d '\r')
log "PERCENTSPACE: $PERCENTSPACE"

UPTIME=$($ADB uptime | tr -d '\r')
log "UPTIME: $UPTIME"

NUM_PHOTOS=$($ADB ls -all /sdcard/Pictures/Frameo | wc -l | tr -d '\r')
log "NUM_PHOTOS: $NUM_PHOTOS"

LAST_PHOTO=$($ADB toybox ls -lt /sdcard/Pictures/Frameo | sed -n '2 p' | cut -d " " -f 6-7 | tr -d '\r')
log "LAST_PHOTO: $LAST_PHOTO"

CURL=curl

curl --location --request POST "$SERVER_URL/frameStatus" \
--header 'Content-Type: application/json' \
--data-binary '{
    "ip": "'"$IP"'",
    "controller_ip": "'"$CONTROLLER_IP"'",
    "network_status": "'"$NETWORK_STATUS"'",
    "log": "'"$LOG"'",
    "uptime": "'"$UPTIME"'",
    "disk_space_remaining": "'"$FREESPACE"'",
    "disk_usage_percent": '"$PERCENTSPACE"',
    "num_photos": '$NUM_PHOTOS',
    "last_photo_update": "'"$LAST_PHOTO"'"
}'

# Log cron setup for diagnostics
crontab -l