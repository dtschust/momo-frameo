#! /bin/sh
adb shell su 0 cp /mnt/media_rw/2307-0820/sd-card.sh /data/local/tmp
adb shell su 0 chmod 777 /data/local/tmp/sd-card.sh
adb shell su 0 /data/local/tmp/sd-card.sh >> /mnt/media_rw/2307-0820/log.txt