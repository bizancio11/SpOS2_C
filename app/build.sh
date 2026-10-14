#!/bin/bash
# Genera 3 ISOs booteables: SpOS2_N.iso, SpOS2_Programer.iso, SpOS2_Premium.iso
# AUTOCONTENIDO: solo necesita este archivo + la carpeta app/ (main.py, core.py, logo.png, ...)
# Requiere: sudo apt install live-build debootstrap debian-archive-keyring xorriso squashfs-tools
# Uso: sudo ./build.sh [N|Programer|Premium]   (sin argumento = las 3)
set -e
[ "$(id -u)" -eq 0 ] || { echo "Ejecuta con sudo"; exit 1; }
ROOT="$(cd "$(dirname "$0")" && pwd)"

if [ ! -d "$ROOT/app" ]; then
  echo "No existe la carpeta app/ junto a build.sh (aqui: $ROOT). Contenido:"; ls -la "$ROOT"; exit 1
fi
for f in main.py core.py logo.png; do
  [ -f "$ROOT/app/$f" ] || { echo "Falta app/$f - copia TODO tu proyecto SpOS2 dentro de la carpeta app/"; ls -la "$ROOT/app"; exit 1; }
done

packages() {
  local base="python3 python3-pygame python3-numpy xserver-xorg xinit x11-xserver-utils alsa-utils"
  case "$1" in
    N) echo $base ;;
    Programer) echo $base python3-pip python3-venv python3-tk idle3 git build-essential nasm gdb vim nano \
                    qemu-system-x86 grub-pc-bin xorriso mtools openbox xterm ;;
    Premium) echo $base pulseaudio mpg123 ffmpeg network-manager network-manager-gnome wpasupplicant \
                    wireless-tools firmware-iwlwifi firmware-realtek firmware-atheros openbox xterm \
                    fonts-dejavu fonts-noto-color-emoji python3-pip python3-tk git nano ;;
  esac
}

build_one() {
  local ed=$1 work="$ROOT/work_$1" edname
  case "$ed" in N) edname=normal;; Programer) edname=programmer;; Premium) edname=premium;; *) echo "Edicion invalida: $ed"; exit 1;; esac
  rm -rf "$work" && mkdir -p "$work" && cd "$work"
  lb config \
    --distribution bookworm \
    --architectures amd64 \
    --archive-areas "main contrib non-free non-free-firmware" \
    --binary-images iso-hybrid \
    --iso-volume "SpOS2_$ed" \
    --bootappend-live "boot=live components quiet splash" \
    --debian-installer none

  # Lista de paquetes (una por linea)
  mkdir -p config/package-lists
  packages "$ed" | tr ' ' '\n' > config/package-lists/spos2.list.chroot

  # App
  mkdir -p config/includes.chroot/opt/spai
  cp -a "$ROOT/app/." config/includes.chroot/opt/spai/
  echo "$edname" > config/includes.chroot/opt/spai/edition.txt

  # Autoarranque: login automatico -> startx -> SpOS2
  mkdir -p config/includes.chroot/etc/skel
  cat > config/includes.chroot/etc/skel/.bash_profile <<'EOF'
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
  exec startx
fi
EOF
  cat > config/includes.chroot/etc/skel/.xinitrc <<'EOF'
#!/bin/sh
xset s off -dpms
[ -x /usr/bin/nm-applet ] && nm-applet &
cd /opt/spai
ED="$(cat /opt/spai/edition.txt 2>/dev/null)"
python3 main.py --edition "$ED" --fullscreen
if [ "$ED" = "programmer" ] && [ -x /usr/bin/xterm ]; then
  xterm
fi
sudo poweroff
EOF
  chmod +x config/includes.chroot/etc/skel/.xinitrc

  lb build
  mv live-image-amd64.hybrid.iso "$ROOT/SpOS2_$ed.iso"
  cd "$ROOT" && rm -rf "$work"
  echo ">> Creada SpOS2_$ed.iso"
}

if [ -n "$1" ]; then build_one "$1"; else
  for ed in N Programer Premium; do build_one "$ed"; done
fi
