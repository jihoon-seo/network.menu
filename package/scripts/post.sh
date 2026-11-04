#!/system/bin/sh
export PATH=/data/nemesis/bin:/sbin:/vendor/bin:/system/sbin:/system/bin:/system/xbin
. ./scripts/common.sh

log "postinstall network.menu"
snapshot_all || exit 1
if ! sys_rw; then
    log "FAIL: remount /system rw"
    exit 1
fi
if ! apply_all; then
    sys_ro
    exit 1
fi
sys_ro
sync
[ -n "$NM_SYS" ] && exit 0
log "rebooting so PackageManager reloads features"
exec /system/bin/reboot
log "FAIL: reboot returned"
exit 1
