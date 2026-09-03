#!/usr/bin/env bash
# Phase 4 : Elgato 4K X (udev, loopback PipeWire), OBS. A lancer en utilisateur normal.
source "$(dirname "$0")/lib.sh"
load_config
need_user
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"

install_pkgs "$REPO_DIR/pkgs/40-media.txt"

# udev : /dev/video-elgato + acces utilisateur
sudo rsync -a --chown=root:root "$REPO_DIR/system/etc/udev/rules.d/71-elgato-4kx.rules" /etc/udev/rules.d/
sudo udevadm control --reload && sudo udevadm trigger --subsystem-match=video4linux 2>/dev/null || true
[[ -e /dev/video-elgato ]] && ok "/dev/video-elgato -> $(readlink /dev/video-elgato)" || warn "Elgato 4K X non detectee (debranchee ?)"

# PipeWire : nom stable du noeud Elgato + loopback permanent
stow_pkg media
systemctl --user restart wireplumber pipewire pipewire-pulse 2>/dev/null || warn "PipeWire non actif dans cette session"
sleep 2
if pw-cli ls Node 2>/dev/null | grep -q 'elgato_4kx_in'; then ok "Noeud audio elgato_4kx_in present, loopback actif"
else warn "Noeud elgato_4kx_in absent : verifier 'pactl list short sources | grep -i elgato'"; fi

# OBS : profil Elgato4KX copie une seule fois (OBS reecrit ses fichiers, pas de symlink)
PROFILE="$CFG/obs-studio/basic/profiles/Elgato4KX"
if [[ ! -d "$PROFILE" ]]; then
  mkdir -p "$PROFILE" "$HOME/Videos/Captures"
  sed "s|@@HOME@@|$HOME|" "$REPO_DIR/templates/obs-profile/basic.ini" > "$PROFILE/basic.ini"
  cp "$REPO_DIR/templates/obs-profile/recordEncoder.json" "$PROFILE/recordEncoder.json"
  ok "Profil OBS Elgato4KX cree (a selectionner dans OBS : Profil > Elgato4KX)"
fi
ok "Phase 4 terminee. Scene OBS : voir docs/40-media.md"
