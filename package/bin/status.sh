#!/system/bin/sh
export PATH=/data/nemesis/bin:/sbin:/vendor/bin:/system/sbin:/system/bin:/system/xbin
. ./scripts/common.sh

echo "id=network.menu"
echo "targetdir=$(getprop ro.mobis.targetdir 2>/dev/null)"
for _n in "$HS_XML" "$WIFI_XML"; do
    if [ -f "$PERM/$_n" ]; then
        echo "perm=present $_n"
    else
        echo "perm=absent $_n"
    fi
done
for _f in "$ONEBIN"/*/featurexml.cfg
do
    [ -f "$_f" ] || continue
    grep "$HS_XML" "$_f" 2>/dev/null | sed "s|^|$_f: |"
done
if pm list features 2>/dev/null | grep -q 'feature:com.hkmc.software.wifihotspot'; then
    echo "pm=wifihotspot on"
else
    echo "pm=wifihotspot off"
fi
if [ -d "$BACKUP_DIR" ]; then
    echo "backup=$BACKUP_DIR"
else
    echo "backup=none"
fi
exit 0
