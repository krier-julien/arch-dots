#!/usr/bin/env bash
# Phase 3 : gaming. A lancer en utilisateur normal.
source "$(dirname "$0")/lib.sh"
load_config
need_user

install_pkgs "$REPO_DIR/pkgs/30-gaming.txt"

# MangoHud + gamemode.ini
stow_pkg gaming

# ntsync : module + droits sur /dev/ntsync
sudo rsync -a --chown=root:root "$REPO_DIR/system/etc/modules-load.d/ntsync.conf" /etc/modules-load.d/
sudo rsync -a --chown=root:root "$REPO_DIR/system/etc/udev/rules.d/70-ntsync.rules" /etc/udev/rules.d/
sudo modprobe ntsync 2>/dev/null || warn "module ntsync absent (noyau < 6.14 ?)"
sudo udevadm control --reload && sudo udevadm trigger --name-match=ntsync 2>/dev/null || true
[[ -c /dev/ntsync ]] && ok "/dev/ntsync present ($(stat -c '%A' /dev/ntsync))" || warn "/dev/ntsync absent"

# gamemode : groupe + verification que le helper V-Cache est utilisable sans mot de passe
getent group gamemode >/dev/null && sudo usermod -aG gamemode "$USER"
sudo -n /usr/local/bin/x3d-mode >/dev/null 2>&1 && ok "x3d-mode utilisable par gamemode" \
  || warn "x3d-mode : sudo sans mot de passe indisponible (phase 1) ou driver amd_x3d_vcache absent"

# Steam : premier lancement necessaire pour creer ~/.local/share/Steam ; rien a configurer par fichier.
ok "Phase 3 terminee. Options de lancement Steam : voir docs/30-gaming.md"
