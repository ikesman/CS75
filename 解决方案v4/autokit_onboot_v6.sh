#!/system/bin/sh
# AutoKit v6 boot script
# Restores native libs + dalvik cache + launches app
LOG=/data/local/tmp/autokit_boot.log
PKG=cn.manstep.phonemirrorBox
ACT=cn.manstep.phonemirrorBox/.CheckActivity
SYSAPK=/system/priv-app/AutoKit.apk
BACKUP=/system/autokit_backup
DCACHE=/data/dalvik-cache
APPLIB=/data/app-lib/cn.manstep.phonemirrorBox-1
DATAAPK=/data/app/cn.manstep.phonemirrorBox-1.apk

log() { echo "$(date) $1" >> $LOG; }
log "===== v6 boot ====="

# Wait for PackageManager
N=0
while [ $N -lt 90 ]; do
    pm list packages >/dev/null 2>&1 && break
    sleep 1
    N=$((N+1))
done
log "pm:${N}s"

# ======= RESTORE NATIVE LIBS =======
if [ ! -d "$APPLIB" ] || [ -z "$(ls $APPLIB 2>/dev/null)" ]; then
    log "restoring native libs..."
    mkdir -p "$APPLIB"
    cp $BACKUP/native_libs/*.so $APPLIB/
    chmod 755 $APPLIB/*.so
    chown 1000:1000 $APPLIB/*.so
    log "native libs restored"
else
    log "native libs OK"
fi

# ======= RESTORE LIB SYMLINK =======
DATADIR=/data/data/$PKG
if [ -d "$DATADIR" ]; then
    # Remove broken symlink and recreate
    rm -f "$DATADIR/lib" 2>/dev/null
    ln -s "$APPLIB" "$DATADIR/lib"
    chown 1012:1012 "$DATADIR/lib" 2>/dev/null
fi

# ======= RESTORE DATA APK =======
if [ ! -f "$DATAAPK" ] && [ -f "$BACKUP/data_app.apk" ]; then
    cp "$BACKUP/data_app.apk" "$DATAAPK"
    chown 1000:1000 "$DATAAPK"
    chmod 644 "$DATAAPK"
    log "data APK restored"
fi

# ======= RESTORE DALVIK CACHE =======
SYS_DEX="$DCACHE/system@priv-app@AutoKit.apk@classes.dex"
DATA_DEX="$DCACHE/data@app@cn.manstep.phonemirrorBox-1.apk@classes.dex"

if [ ! -f "$DATA_DEX" ] && [ -f "$BACKUP/autokit_data.dex" ]; then
    cp "$BACKUP/autokit_data.dex" "$DATA_DEX"
    chown 1000:50038 "$DATA_DEX"
    chmod 644 "$DATA_DEX"
    log "data dex restored"
fi
if [ ! -f "$SYS_DEX" ] && [ -f "$BACKUP/autokit_sys.dex" ]; then
    cp "$BACKUP/autokit_sys.dex" "$SYS_DEX"
    chown 1000:10038 "$SYS_DEX"
    chmod 644 "$SYS_DEX"
    log "sys dex restored"
fi

# ======= VERIFY PACKAGE =======
INSTALLED=$(pm path $PKG 2>/dev/null)
if [ -z "$INSTALLED" ]; then
    log "pkg missing, pm install..."
    pm install -r "$SYSAPK" 2>/dev/null
    log "install:$?"
    sleep 3
else
    log "pkg:$INSTALLED"
fi

# ======= LAUNCH =======
sleep 1
am start -n "$ACT" 2>/dev/null
R=$?
log "launch:$R"
if [ $R -ne 0 ]; then
    sleep 2
    am start -n "$PKG/.MainActivity" 2>/dev/null
    log "retry:$?"
fi
log "===== v6 done ====="

# ADB over WiFi (last step to avoid killing adb session)
setprop service.adb.tcp.port 5555
stop adbd 2>/dev/null
start adbd 2>/dev/null
log "ADB:5555"
