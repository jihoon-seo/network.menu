#!/system/bin/sh
export PATH=/data/nemesis/bin:/sbin:/vendor/bin:/system/sbin:/system/bin:/system/xbin
. ./scripts/common.sh

log "preinstall network.menu"
if [ -z "$NM_SYS" ] && [ ! -x /system/xbin/nemesis ]; then
    log "FAIL: /system/xbin/nemesis missing"
    exit 1
fi
if [ ! -d "$PERM" ]; then
    log "FAIL: $PERM missing"
    exit 1
fi
for _n in "$HS_XML" "$WIFI_XML"; do
    if [ ! -f "files/permissions/$_n" ]; then
        log "FAIL: missing files/permissions/$_n"
        exit 1
    fi
done
# The menu code was mapped on the KR one-bin build (KMC.KOR V039).
case "$(getprop ro.mobis.targetdir 2>/dev/null)" in
    *_kr|"") ;;
    *) log "WARN: not a KR one-bin ($(getprop ro.mobis.targetdir 2>/dev/null)), untested" ;;
esac
log "preinstall ok"
exit 0
