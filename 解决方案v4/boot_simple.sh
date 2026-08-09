#!/system/bin/sh
# AutoKit boot - simple reinstall
LOG=/data/local/tmp/autokit_boot.log
echo "$(date) boot start" > $LOG

# wait for pm
N=0
while [ $N -lt 90 ]; do
    pm list packages >/dev/null 2>&1 && break
    sleep 1
    N=$((N+1))
done
echo "$(date) pm:${N}s" >> $LOG

# force reinstall
pm install -r /system/priv-app/AutoKit.apk >> $LOG 2>&1
echo "$(date) install:$?" >> $LOG
sleep 3

# launch
am start -n cn.manstep.phonemirrorBox/.CheckActivity >> $LOG 2>&1
echo "$(date) launch:$?" >> $LOG

# enable wifi adb
setprop service.adb.tcp.port 5555
stop adbd 2>/dev/null
start adbd 2>/dev/null
echo "$(date) done" >> $LOG
