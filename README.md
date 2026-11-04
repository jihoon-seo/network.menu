# network.menu

[한국어](README.ko.md)

A [NEMESIS](https://github.com/xwtk/hmg_nemesis) package for Gen5W head units that brings back
**Settings > Data/Network** with its **Wi-Fi** and **Hotspot** tabs, where the Korean firmware
only shows the Kia Connect page.

> **Tested on one car only:** firmware `DE22EV.KOR.0000.V039.001.260902` (onebin `de22ev_kr`).
> Unofficial; see [Disclaimer](#disclaimer).

## Why

The Settings app shows "Data/Network" (Kia Connect + Wi-Fi + Hotspot tabs) instead of the Kia
Connect page only when the unit has the feature `com.hkmc.software.wifihotspot`, and its Wi-Fi tab
also needs `android.hardware.wifi`. Every Korean onebin's `featurexml.cfg` removes the hotspot
feature with a `-/system/etc/permissions/com.hkmc.software.wifihotspot.xml` line, and the image does
not ship the feature file.

## What it does

On install (as root, from NEMESIS):

1. Takes a snapshot of every file it will touch into `/data/nemesis/backup/network.menu/`
   (a file that does not exist is recorded as absent).
2. Comments out (`#`) the `wifihotspot` removal line in each `/system/onebin/*/featurexml.cfg`
   that has one. Other lines, CRLF line endings and other onebins are left as they are.
3. Adds `/system/etc/permissions/com.hkmc.software.wifihotspot.xml` and `android.hardware.wifi.xml`.
4. Reboots, so PackageManager reloads the features.

Uninstall writes the snapshot back byte for byte and removes the files that were absent. If
[wireless.projection](https://github.com/xwtk/hmg_nemesis/tree/main/Sources/packages/wireless-projection)
is installed, it keeps `android.hardware.wifi.xml`, which that package also needs. An update over an
installed copy keeps the first snapshot.

The menu is only the switch: the Wi-Fi tab works when the unit has a Wi-Fi chip (the tested unit
does; its driver loads only when Wi-Fi is turned on).

## Requirements

- [NEMESIS](https://github.com/xwtk/hmg_nemesis) on the head unit.
- A Korean (`*_kr`) onebin. Other onebins install with a warning, untested.

## Install

Download from [Releases](../../releases):

| asset | what |
|---|---|
| `network.menu-<version>.USB.zip` | USB stick layout: `NEMESIS.data` + `packages/`, plus usage notes |
| `network.menu-<version>.zip` | the NEMESIS package itself |
| `SHA256SUMS` | checksums of both |

1. Put `NEMESIS.data` and the `packages` folder from the USB zip at the top of a USB stick.
2. Start the car, wait about a minute, insert the stick and confirm the install (or update) in NEMESIS.
3. The head unit reboots by itself; Settings then shows "Data/Network".

Remove it from the NEMESIS Manager, then reboot the head unit. Log on the car:
`/data/nemesis/network.menu.log`.

## Build and test

```
./build.sh          # -> dist/ (needs Python 3)
./tests/run.sh      # host test: install, update and uninstall on a fake /system and /data
```

The host test runs the package's own scripts with `NM_SYS` / `NM_DATA` pointing at a fake tree, and
checks the result file by file, including that uninstall gives back the original bytes.

## Disclaimer

This is an unofficial hobby project. It is not affiliated with or endorsed by Hyundai Motor Group,
Kia, Hyundai Mobis or the NEMESIS authors. It changes files in `/system`; a failed change can leave
the head unit misbehaving, and modifying it can void a warranty. Tested on one car and one firmware
only. Use it at your own risk; the software comes with no warranty (see [LICENSE](LICENSE)).

## License

[GNU AGPL-3.0](LICENSE). The scripts are modified from xwtk/hmg_nemesis's wireless-projection
package (AGPL-3.0); see [NOTICE](NOTICE.md).
