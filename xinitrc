#!/bin/sh
xset s off -dpms
[ -x /usr/bin/nm-applet ] && nm-applet &
cd /opt/spai
ED="$(cat /opt/spai/edition.txt 2>/dev/null)"
SPOS2_FULLSCREEN=1 python3 main.py --edition "$ED" --fullscreen
# Al cerrar SpOS2: Programmer abre una terminal, las demas apagan
if [ "$ED" = "programmer" ] && [ -x /usr/bin/xterm ]; then
  xterm
fi
sudo poweroff
