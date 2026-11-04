#!/system/bin/sh
# network.menu — show Settings > Data/Network (Kia Connect / Wi-Fi / Hotspot tabs).
#
# Settings_W shows Data/Network instead of Kia Connect when
# com.hkmc.Feature.hasFeature("com.hkmc.software.wifihotspot") is true
# (SDefine.isDataNetworkEnabled). Every KR onebin featurexml.cfg strips that
# XML with a "-" line, and the image does not ship it. The Wi-Fi tab of
# NetworkConnectionSettings also needs android.hardware.wifi.
#
# Snapshot the live unit, then change it. Uninstall writes the snapshot back.
# NM_SYS / NM_DATA exist only for host tests.

export PATH=/data/nemesis/bin:/sbin:/vendor/bin:/system/sbin:/system/bin:/system/xbin
export LD_LIBRARY_PATH=/vendor/lib:/system/lib
[ -n "$NM_SYS" ] && PATH=$PATH:$NM_HOST_PATH

SYS=${NM_SYS:-/system}
DATA=${NM_DATA:-/data}
PERM=$SYS/etc/permissions
ONEBIN=$SYS/onebin
BACKUP_DIR=$DATA/nemesis/backup/network.menu
LOG=$DATA/nemesis/network.menu.log
# wireless.projection also owns android.hardware.wifi.xml
WP_BACKUP=$DATA/nemesis/backup/wireless.projection

HS_XML=com.hkmc.software.wifihotspot.xml
WIFI_XML=android.hardware.wifi.xml

log() {
    local _msg="$1"
    echo "$_msg"
    mkdir -p "$DATA/nemesis" 2>/dev/null || true
    echo "$_msg" >> "$LOG" 2>/dev/null || true
}

# print is an mksh builtin. This HU has no printf. bash host tests use printf.
# Windows hosts have print.exe, so host tests skip print.
putline() {
    [ -z "$NM_SYS" ] && print -r -- "$1" 2>/dev/null && return 0
    printf '%s\n' "$1"
}

sys_rw() {
    [ -n "$NM_SYS" ] && return 0
    /system/xbin/nemesis remount rw >/dev/null 2>&1 && return 0
    mount -o remount,rw /system 2>/dev/null && return 0
    mount -o rw,remount /system 2>/dev/null && return 0
    mount -o rw,remount / 2>/dev/null && return 0
    return 1
}

sys_ro() {
    [ -n "$NM_SYS" ] && return 0
    /system/xbin/nemesis remount ro >/dev/null 2>&1 || true
    mount -o remount,ro /system 2>/dev/null || true
    mount -o ro,remount /system 2>/dev/null || true
}

remove_backup_dir() {
    case "$BACKUP_DIR" in
        */nemesis/backup/network.menu) ;;
        *)
            log "FAIL: refusing to remove $BACKUP_DIR"
            return 1
            ;;
    esac
    rm -rf "$BACKUP_DIR"
}

commit_tmp() {
    local _dst="$1"
    local _tmp="$2"
    if [ -s "$_dst" ] && [ ! -s "$_tmp" ]; then
        log "FAIL: refuse empty rewrite of $_dst"
        rm -f "$_tmp" 2>/dev/null || true
        return 1
    fi
    cp -f "$_tmp" "$_dst" || return 1
    chmod 644 "$_dst" 2>/dev/null || true
    chown 0.0 "$_dst" 2>/dev/null || chown 0:0 "$_dst" 2>/dev/null || true
    rm -f "$_tmp" 2>/dev/null || true
    return 0
}

snap_file() {
    local _src="$1"
    local _dst="$2"
    local _abs="$3"
    if [ -s "$_dst" ] || [ -s "$_abs" ]; then
        log "snapshot exists for $_src - keeping original"
        return 0
    fi
    if [ -f "$_src" ]; then
        cp -f "$_src" "$_dst" || return 1
        chmod 644 "$_dst" 2>/dev/null || true
        log "backed up $_src"
    else
        putline absent > "$_abs" || return 1
        log "absent on unit: $_src"
    fi
    return 0
}

restore_owned_file() {
    local _live="$1"
    local _bak="$2"
    local _abs="$3"
    if [ -s "$_bak" ]; then
        cp -f "$_bak" "$_live" || return 1
        chmod 644 "$_live" 2>/dev/null || true
        chown 0.0 "$_live" 2>/dev/null || chown 0:0 "$_live" 2>/dev/null || true
        log "restored $_live"
        return 0
    fi
    if [ -s "$_abs" ]; then
        rm -f "$_live" || return 1
        log "removed $_live (absent on the unit at install)"
        return 0
    fi
    log "FAIL: no snapshot for $_live"
    return 1
}

restore_edited_file() {
    local _live="$1"
    local _bak="$2"
    local _abs="$3"
    if [ -s "$_bak" ]; then
        cp -f "$_bak" "$_live" || return 1
        chmod 644 "$_live" 2>/dev/null || true
        chown 0.0 "$_live" 2>/dev/null || chown 0:0 "$_live" 2>/dev/null || true
        log "restored $_live"
        return 0
    fi
    if [ -s "$_abs" ]; then
        log "left absent: $_live"
        return 0
    fi
    log "FAIL: no snapshot for $_live"
    return 1
}

wp_installed() {
    [ -s "$WP_BACKUP/saved" ] && [ ! -s "$WP_BACKUP/restored" ]
}

has_hotspot() {
    grep -q 'wifihotspot' "$1" 2>/dev/null
}

# Every $ONEBIN/*/featurexml.cfg that names wifihotspot is patched.
# ro.mobis.targetdir is not read, so a second variant is not skipped.
snap_featurexmls() {
    local _f _key _n=0
    for _f in "$ONEBIN"/*/featurexml.cfg
    do
        [ -f "$_f" ] || continue
        has_hotspot "$_f" || continue
        _key=${_f#$ONEBIN/}
        _key=${_key%/featurexml.cfg}
        case "$_key" in
            *[!A-Za-z0-9._-]*|"")
                log "FAIL: featurexml path $_f"
                return 1
                ;;
        esac
        putline "$_key $_f" >> "$BACKUP_DIR/featurexml.list" || return 1
        snap_file "$_f" "$BACKUP_DIR/featurexml.${_key}.cfg" "$BACKUP_DIR/featurexml.${_key}.absent" || return 1
        _n=$((_n + 1))
    done
    if [ "$_n" -eq 0 ]; then
        rm -f "$BACKUP_DIR/featurexml.list" 2>/dev/null || true
        putline absent > "$BACKUP_DIR/featurexml.absent" || return 1
        log "no featurexml.cfg with wifihotspot entries"
    fi
    return 0
}

# $1 is apply or restore. Paths come from the snapshot list.
walk_featurexml() {
    local _mode="$1"
    local _line _key _fx
    if [ -s "$BACKUP_DIR/featurexml.absent" ] && [ ! -s "$BACKUP_DIR/featurexml.list" ]; then
        log "featurexml unchanged (none with wifihotspot entries)"
        return 0
    fi
    if [ ! -s "$BACKUP_DIR/featurexml.list" ]; then
        log "FAIL: no featurexml snapshot"
        return 1
    fi
    while IFS= read -r _line || [ -n "$_line" ]; do
        [ -n "$_line" ] || continue
        _key=${_line%% *}
        _fx=${_line#* }
        case "$_key" in
            *[!A-Za-z0-9._-]*|"")
                log "FAIL: bad featurexml key"
                return 1
                ;;
        esac
        case "$_fx" in
            "$ONEBIN/$_key/featurexml.cfg") ;;
            *)
                log "FAIL: bad featurexml path $_fx"
                return 1
                ;;
        esac
        if [ "$_mode" = apply ]; then
            if [ -f "$_fx" ]; then
                rewrite_featurexml "$_fx" || return 1
            else
                log "WARN: featurexml missing at $_fx"
            fi
        else
            restore_edited_file "$_fx" "$BACKUP_DIR/featurexml.${_key}.cfg" "$BACKUP_DIR/featurexml.${_key}.absent" || return 1
        fi
    done < "$BACKUP_DIR/featurexml.list"
    return 0
}

# PackageManagerService and com.hkmc.Feature only act on lines that start
# with "+" or "-", so a leading "#" turns the removal off. Some variants ship
# CRLF: strip \r only for matching and keep the original bytes.
[ -z "$NM_SYS" ] && CR=$(print -r -- $'\r' 2>/dev/null)
[ -n "$CR" ] || CR=$'\r'
rewrite_featurexml() {
    local _fx="$1"
    local _tmp="$BACKUP_DIR/rewrite.tmp"
    local _line
    local _match
    local _n=0
    : > "$_tmp" || return 1
    while IFS= read -r _line || [ -n "$_line" ]; do
        _match="$_line"
        case "$_match" in
            *"$CR") _match="${_match%$CR}" ;;
        esac
        case "$_match" in
            \#*)
                putline "$_line" >> "$_tmp" || return 1
                ;;
            *"$HS_XML")
                putline "#${_line}" >> "$_tmp" || return 1
                _n=$((_n + 1))
                ;;
            *)
                putline "$_line" >> "$_tmp" || return 1
                ;;
        esac
    done < "$_fx"
    commit_tmp "$_fx" "$_tmp" || return 1
    log "patched $_fx (commented $_n wifihotspot lines)"
    return 0
}

apply_perm() {
    local _name="$1"
    local _src="files/permissions/$_name"
    local _dst="$PERM/$_name"
    if [ ! -f "$_src" ]; then
        log "FAIL: missing $_src"
        return 1
    fi
    mkdir -p "$PERM" || return 1
    cp -f "$_src" "$_dst" || return 1
    chmod 644 "$_dst" 2>/dev/null || true
    chown 0.0 "$_dst" 2>/dev/null || chown 0:0 "$_dst" 2>/dev/null || true
    log "applied $_dst"
    return 0
}

kick_apps() {
    am force-stop com.android.settings 2>/dev/null || true
    am force-stop com.hkmc.wifisettings 2>/dev/null || true
}

snapshot_all() {
    case "$BACKUP_DIR" in
        */nemesis/backup/network.menu) ;;
        *)
            log "FAIL: bad backup dir"
            return 1
            ;;
    esac
    if [ -s "$BACKUP_DIR/saved" ]; then
        log "backup already exists ($BACKUP_DIR) - keeping original"
        return 0
    fi
    if [ ! -d "$PERM" ]; then
        log "FAIL: $PERM missing"
        return 1
    fi
    remove_backup_dir || return 1
    mkdir -p "$BACKUP_DIR" || return 1
    snap_featurexmls || return 1
    snap_file "$PERM/$HS_XML" "$BACKUP_DIR/perm.$HS_XML" "$BACKUP_DIR/perm.$HS_XML.absent" || return 1
    snap_file "$PERM/$WIFI_XML" "$BACKUP_DIR/perm.$WIFI_XML" "$BACKUP_DIR/perm.$WIFI_XML.absent" || return 1
    putline 1 > "$BACKUP_DIR/saved" || return 1
    log "snapshotted live unit to $BACKUP_DIR"
    return 0
}

apply_all() {
    if [ ! -s "$BACKUP_DIR/saved" ]; then
        log "FAIL: no snapshot"
        return 1
    fi
    walk_featurexml apply || return 1
    apply_perm "$HS_XML" || return 1
    apply_perm "$WIFI_XML" || return 1
    kick_apps
    rm -f "$BACKUP_DIR/rewrite.tmp" 2>/dev/null || true
    sync
    log "applied network.menu"
    return 0
}

restore_all() {
    local _rc=0
    if [ ! -s "$BACKUP_DIR/saved" ]; then
        log "FAIL: no snapshot to restore"
        return 1
    fi
    if ! sys_rw; then
        log "FAIL: remount /system rw"
        return 1
    fi
    walk_featurexml restore || _rc=1
    restore_owned_file "$PERM/$HS_XML" "$BACKUP_DIR/perm.$HS_XML" "$BACKUP_DIR/perm.$HS_XML.absent" || _rc=1
    if wp_installed; then
        log "kept $PERM/$WIFI_XML (wireless.projection installed)"
    else
        restore_owned_file "$PERM/$WIFI_XML" "$BACKUP_DIR/perm.$WIFI_XML" "$BACKUP_DIR/perm.$WIFI_XML.absent" || _rc=1
    fi
    kick_apps
    rm -f "$BACKUP_DIR/rewrite.tmp" 2>/dev/null || true
    if [ "$_rc" -ne 0 ]; then
        sys_ro
        log "FAIL: restore incomplete, snapshot kept at $BACKUP_DIR"
        return 1
    fi
    putline 1 > "$BACKUP_DIR/restored" 2>/dev/null || true
    sync
    sys_ro
    log "restore complete"
    return 0
}
