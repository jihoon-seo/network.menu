#!/bin/bash
# Host test of the network.menu NEMESIS package: runs its install and uninstall scripts on a
# fake /system and /data tree (NM_SYS / NM_DATA) and checks every file they touch.
set -u
HERE=$(cd "$(dirname "$0")" && pwd)
PKG="$HERE/../package"
WORK=$(mktemp -d); trap 'rm -rf "$WORK"' EXIT
FAILED=0
pass() { echo "PASS $1"; }
fail() { echo "FAIL $1: $2"; FAILED=$((FAILED+1)); }

HS=com.hkmc.software.wifihotspot.xml
WIFI=android.hardware.wifi.xml
STOCK_CFG='+/system/etc/permissions/com.hkmc.software.vehiclesetting.xml
-/system/etc/permissions/com.hkmc.software.wifihotspot.xml
-/system/etc/permissions/com.hkmc.software.connectivity.carplay_wireless.xml
-/system/etc/permissions/com.hkmc.software.connectivity.androidauto_wireless.xml'

# unit [crlf]: a fresh fake head unit in $U (sys/, data/, the package's own copy)
unit() {
    U="$WORK/u$RANDOM"
    mkdir -p "$U/sys/etc/permissions" "$U/sys/onebin/de22ev_kr" "$U/sys/onebin/other_kr" "$U/data" "$U/bin" "$U/pkg"
    if [ "${1:-}" = crlf ]; then printf '%s\n' "$STOCK_CFG" | sed 's/$/\r/' > "$U/sys/onebin/de22ev_kr/featurexml.cfg"
    else printf '%s\n' "$STOCK_CFG" > "$U/sys/onebin/de22ev_kr/featurexml.cfg"; fi
    printf '+/system/etc/permissions/com.hkmc.software.vehiclesetting.xml\n' > "$U/sys/onebin/other_kr/featurexml.cfg"
    echo '<permissions><feature name="com.hkmc.software.vehiclesetting" /></permissions>' > "$U/sys/etc/permissions/com.hkmc.software.vehiclesetting.xml"
    cp -r "$PKG/." "$U/pkg/"
    printf '#!/bin/bash\n[ "$1" = ro.mobis.targetdir ] && echo de22ev_kr\n' > "$U/bin/getprop"
    printf '#!/bin/bash\necho "am $*" >> "%s/am.log"\n' "$U" > "$U/bin/am"
    printf '#!/bin/bash\nfor f in %s/sys/etc/permissions/*.xml; do sed -n "s/.*feature name=\\"\\([^\\"]*\\)\\".*/feature:\\1/p" "$f"; done\n' "$U" > "$U/bin/pm"
    chmod +x "$U/bin/"*
    cp -r "$U/sys" "$U/sys.orig"
}
# run SCRIPT: one of the package's scripts, as NEMESIS runs it (cwd = package dir)
run() {
    (cd "$U/pkg" && NM_SYS="$U/sys" NM_DATA="$U/data" NM_HOST_PATH="$U/bin:/usr/bin:/bin" bash "$1") > "$U/out.$(basename "$1")" 2>&1
}
install() { run scripts/pre.sh && run scripts/post.sh; }
same_tree() { diff -r "$U/sys.orig" "$U/sys" > /dev/null; }

# 1. install on a stock unit
unit
install
CFG="$U/sys/onebin/de22ev_kr/featurexml.cfg"
if grep -qx "#-/system/etc/permissions/$HS" "$CFG" && ! grep -qx -- "-/system/etc/permissions/$HS" "$CFG" \
    && grep -qx -- "-/system/etc/permissions/com.hkmc.software.connectivity.carplay_wireless.xml" "$CFG" \
    && cmp -s "$U/sys/etc/permissions/$HS" "$PKG/files/permissions/$HS" && cmp -s "$U/sys/etc/permissions/$WIFI" "$PKG/files/permissions/$WIFI" \
    && cmp -s "$U/sys/onebin/other_kr/featurexml.cfg" "$U/sys.orig/onebin/other_kr/featurexml.cfg"; then
    pass "install: hotspot removal commented out, both features added, other lines and onebins untouched"
else fail "install" "$(cat "$U/out.post.sh")"; fi
grep -q "rebooting" "$U/out.post.sh" && fail "install" "post.sh tried to reboot in a host test" || pass "install: no reboot on the host"

# 2. status
run bin/status.sh
grep -q "perm=present $HS" "$U/out.status.sh" && grep -q "pm=wifihotspot on" "$U/out.status.sh" \
    && pass "status: features present" || fail "status" "$(cat "$U/out.status.sh")"

# 3. uninstall gives the stock tree back, byte for byte
run scripts/preun.sh
same_tree && [ ! -d "$U/data/nemesis/backup/network.menu" ] \
    && pass "uninstall: /system identical to before, snapshot removed" || fail "uninstall" "$(diff -r "$U/sys.orig" "$U/sys" | head -5)"

# 4. CRLF featurexml: line endings kept, restored byte for byte
unit crlf
install
CFG="$U/sys/onebin/de22ev_kr/featurexml.cfg"
# (count CRs with tr: grep on Windows hosts drops a trailing CR when it reads lines)
if tr -d '\r' < "$CFG" | grep -qx "#-/system/etc/permissions/$HS" && [ "$(tr -cd '\r' < "$CFG" | wc -c | tr -d ' ')" = 4 ]; then
    pass "CRLF: commented, every line keeps its CR"
else fail "CRLF" "$(od -c "$CFG" | head -3)"; fi
run scripts/preun.sh
same_tree && pass "CRLF: uninstall restores the original bytes" || fail "CRLF uninstall" "differs"

# 5. update over an installed copy (NEMESIS runs pre + post again), then uninstall
unit
install
install
CFG="$U/sys/onebin/de22ev_kr/featurexml.cfg"
[ "$(grep -c "^#" "$CFG")" = 1 ] && pass "update: no second # on the same line" || fail "update" "$(cat "$CFG")"
run scripts/preun.sh
same_tree && pass "update then uninstall: original kept from the first install" || fail "update uninstall" "differs"

# 6. wireless.projection installed (owns android.hardware.wifi.xml): uninstall keeps that file
unit
cp "$PKG/files/permissions/$WIFI" "$U/sys/etc/permissions/$WIFI"; cp "$U/sys/etc/permissions/$WIFI" "$U/sys.orig/etc/permissions/$WIFI"
mkdir -p "$U/data/nemesis/backup/wireless.projection"; echo 1 > "$U/data/nemesis/backup/wireless.projection/saved"
install
rm -f "$U/sys/etc/permissions/$WIFI" && cp "$PKG/files/permissions/$WIFI" "$U/sys/etc/permissions/$WIFI"
run scripts/preun.sh
[ -f "$U/sys/etc/permissions/$WIFI" ] && [ ! -f "$U/sys/etc/permissions/$HS" ] \
    && grep -q "kept .*$WIFI (wireless.projection installed)" "$U/out.preun.sh" \
    && pass "wireless.projection installed: wifi feature kept, hotspot feature removed" || fail "wp" "$(cat "$U/out.preun.sh")"

# 7. a unit whose featurexml has no hotspot line: nothing to comment, uninstall still clean
unit
printf '+/system/etc/permissions/com.hkmc.software.vehiclesetting.xml\n' > "$U/sys/onebin/de22ev_kr/featurexml.cfg"; cp "$U/sys/onebin/de22ev_kr/featurexml.cfg" "$U/sys.orig/onebin/de22ev_kr/featurexml.cfg"
install
grep -q "no featurexml.cfg with wifihotspot entries" "$U/out.post.sh" && cmp -s "$U/sys/onebin/de22ev_kr/featurexml.cfg" "$U/sys.orig/onebin/de22ev_kr/featurexml.cfg" \
    && pass "no hotspot line: featurexml untouched" || fail "no hotspot line" "$(cat "$U/out.post.sh")"
run scripts/preun.sh
same_tree && pass "no hotspot line: uninstall clean" || fail "no hotspot uninstall" "differs"

[ "$FAILED" = 0 ] && echo "network.menu: all checks passed" || { echo "network.menu: $FAILED check(s) failed"; exit 1; }
