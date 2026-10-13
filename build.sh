#!/bin/bash
# Genera 3 ISOs booteables: SpOS2_N.iso, SpOS2_Programer.iso, SpOS2_Premium.iso
# Requiere (Debian/Ubuntu/Mint): sudo apt install live-build debootstrap debian-archive-keyring xorriso squashfs-tools
# Uso: sudo ./build.sh [N|Programer|Premium]   (sin argumento = las 3)
set -e
[ "$(id -u)" -eq 0 ] || { echo "Ejecuta con sudo"; exit 1; }
ROOT="$(cd "$(dirname "$0")" && pwd)"

for f in main.py core.py logo.png; do
  [ -f "$ROOT/app/$f" ] || { echo "Falta app/$f - copia TODO tu proyecto SpOS2 (core.py, logo.png, etc.) dentro de la carpeta app/"; exit 1; }
done

build_one() {
  local ed=$1 work="$ROOT/work_$1"
  rm -rf "$work" && mkdir -p "$work" && cd "$work"
  lb config \
    --distribution bookworm \
    --architectures amd64 \
    --archive-areas "main contrib non-free non-free-firmware" \
    --binary-images iso-hybrid \
    --iso-volume "SpOS2_$ed" \
    --bootappend-live "boot=live components quiet splash" \
    --debian-installer none
  cp "$ROOT/editions/$ed.list" config/package-lists/spos2.list.chroot
  mkdir -p config/includes.chroot/opt/spai
  mkdir -p config/includes.chroot/etc/skel
  cp "$ROOT/skel/bash_profile" config/includes.chroot/etc/skel/.bash_profile
  cp "$ROOT/skel/xinitrc" config/includes.chroot/etc/skel/.xinitrc
  chmod +x config/includes.chroot/etc/skel/.xinitrc
  cp -a "$ROOT/app/." config/includes.chroot/opt/spai/
  case "$ed" in N) echo normal;; Programer) echo programmer;; Premium) echo premium;; esac \
    > config/includes.chroot/opt/spai/edition.txt
  lb build
  mv live-image-amd64.hybrid.iso "$ROOT/SpOS2_$ed.iso"
  cd "$ROOT" && rm -rf "$work"
  echo ">> Creada SpOS2_$ed.iso"
}

if [ -n "$1" ]; then build_one "$1"; else
  for ed in N Programer Premium; do build_one "$ed"; done
fi
