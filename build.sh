#!/bin/bash
# Builds the release assets into dist/:
#   network.menu-<version>.zip       the NEMESIS package
#   network.menu-<version>.USB.zip   a USB stick layout that installs it (NEMESIS.data + packages/)
#   SHA256SUMS
# Needs Python 3 (PYTHON, default python).
set -euo pipefail
cd "$(dirname "$0")"
PY=${PYTHON:-python}
VERSION=$(sed -n 's/^package-version=//p' package/NEMESIS.data)
ID=$(sed -n 's/^id=//p' package/NEMESIS.data)
PKG=$ID-$VERSION.zip
grep -qx "path=packages/$PKG" usb/NEMESIS.data || { echo "usb/NEMESIS.data does not name packages/$PKG" >&2; exit 1; }
echo "building $ID $VERSION"

rm -rf build dist
mkdir -p build/usb/packages dist
"$PY" tools/zipdir.py package "dist/$PKG"
cp usb/NEMESIS.data usb/USAGE.en.txt usb/사용방법.txt build/usb/
cp "dist/$PKG" build/usb/packages/
"$PY" tools/zipdir.py build/usb "dist/$ID-$VERSION.USB.zip"
(cd dist && sha256sum "$PKG" "$ID-$VERSION.USB.zip" > SHA256SUMS)
cat dist/SHA256SUMS
