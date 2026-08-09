#!/system/bin/sh
# AutoKit boot v7 - simple & reliable
LOG=/data/local/tmp/autokit_boot.log
echo "$(date) boot" > $LOG

# wait pm
N=0
while [ $N -lt 90 ]; do
    pm list packages >/dev/null 2>&1 && break
    sleep 1
    N=$((N+1))
done
echo "$(date) pm:${N}s" >> $LOG

# check if registered
P=$(pm path cn.manstep.phonemirrorBox 2>/dev/null)
echo "$(date) path:$P" >> $LOG

if [ -z "$P" ]; then
    pm install -r /system/priv-app/AutoKit.apk >> $LOG 2>&1
    echo "$(date) install:$?" >> $LOG
    sleep 3
fi

# launch
am start -n cn.manstep.phonemirrorBox/.CheckActivity >> $LOG 2>&1
echo "$(date) launch:$?" >> $LOG

# adb wifi
setprop service.adb.tcp.port 5555
stop adbd 2>/dev/null
start adbd 2>/dev/null
echo "$(date) done" >> $LOG
