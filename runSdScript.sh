#! /bin/sh
echo "--------------------------------"
date
echo "Running SD script!"
adb shell su 0 cp /mnt/media_rw/2307-0820/sd-card.sh /data/local/tmp
adb shell su 0 chmod 777 /data/local/tmp/sd-card.sh
adb shell su 0 "/data/local/tmp/sd-card.sh >> /data/local/tmp/log.txt"
adb shell su 0 cp /data/local/tmp/log.txt /mnt/media_rw/2307-0820/
