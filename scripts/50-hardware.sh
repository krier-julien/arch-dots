#!/usr/bin/env bash
# Phase 5 : liquidctl (Kraken Elite + hub Lian Li Uni SL V2), vitesses fixes. Utilisateur normal.
source "$(dirname "$0")/lib.sh"
load_config
need_user

install_pkgs "$REPO_DIR/pkgs/50-hardware.txt"
v=$(liquidctl --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' | head -1)
[[ -n "$v" ]] && python3 -c "import sys; sys.exit(0 if tuple(map(int,'$v'.split('.')))>=(1,16) else 1)" \
  || warn "liquidctl $v < 1.16 : le driver Lian Li Uni est absent"

for f in etc/liquidctl/speeds.conf etc/systemd/system/liquidctl-apply.service etc/systemd/system/liquidctl-resume.service usr/local/bin/liquidctl-apply; do
  sudo rsync -a --chown=root:root "$REPO_DIR/system/$f" "/$f"
done
sudo chmod 0755 /usr/local/bin/liquidctl-apply
sudo udevadm control --reload; sudo udevadm trigger
sudo systemctl daemon-reload
sudo systemctl enable --now liquidctl-apply.service liquidctl-resume.service
sudo systemctl --no-pager --lines=20 status liquidctl-apply.service || true
ok "Phase 5 terminee. Ajuster /etc/liquidctl/speeds.conf (copie de system/etc/liquidctl/speeds.conf)"
