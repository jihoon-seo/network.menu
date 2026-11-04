# Notice

network.menu is licensed under the GNU Affero General Public License v3.0 (LICENSE).

`scripts/common.sh` was modified in 2026-11 from
`Sources/packages/wireless-projection/scripts/common.sh` of
[xwtk/hmg_nemesis](https://github.com/xwtk/hmg_nemesis) (AGPL-3.0), commit
`345f171850c35742f84f0fbe511d0b7ab50364fc`. It keeps that script's snapshot/apply/restore
structure (snapshot the live unit, change it, write the snapshot back on uninstall) and its
helpers, and changes what is applied: the `com.hkmc.software.wifihotspot` and
`android.hardware.wifi` features, and the `featurexml.cfg` lines that remove the hotspot feature.
It also leaves `android.hardware.wifi.xml` in place on uninstall while wireless.projection is
installed.

`scripts/pre.sh`, `scripts/post.sh`, `scripts/preun.sh` and `bin/status.sh` were likewise
modified from the same package's scripts of the same names (same commit): the checks and the
status lines are for this package's features. The feature XMLs in `files/permissions/` are the
two feature declarations the package installs.

Source: https://github.com/jihoon-seo/network.menu
