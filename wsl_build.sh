#!/bin/bash
# Lo ejecuta build_isos.bat dentro de WSL (Ubuntu). $1 = carpeta del proyecto en Windows (ruta WSL)
set -e
SRC="$1"
WORK=/root/spos2_build
apt-get update
apt-get install -y live-build debootstrap debian-archive-keyring xorriso squashfs-tools rsync dos2unix
rm -rf "$WORK" && mkdir -p "$WORK"
# Se construye en el disco de Linux (NTFS no sirve para debootstrap)
rsync -a --exclude '*.iso' --exclude 'work_*' "$SRC"/ "$WORK"/
cd "$WORK"
find build.sh editions skel -type f -exec dos2unix -q {} +
chmod +x build.sh
./build.sh
cp -f SpOS2_*.iso "$SRC"/
echo "Listo: ISOs copiadas a $SRC"
