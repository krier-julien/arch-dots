#!/usr/bin/env bash
# Phase 7 : nxapi (presence Switch -> Discord). Utilisateur normal.
source "$(dirname "$0")/lib.sh"
load_config
need_user

install_pkgs "$REPO_DIR/pkgs/70-services.txt"
# npm global dans ~/.local, sans sudo
npm config set prefix "$HOME/.local" >/dev/null
if ! command -v "$HOME/.local/bin/nxapi" >/dev/null; then
  info "npm install -g nxapi"; npm install -g nxapi
else
  npm update -g nxapi >/dev/null 2>&1 || true
fi
stow_pkg nxapi
systemctl --user daemon-reload
if [[ -f "$HOME/.config/nxapi/presence.env" ]]; then
  systemctl --user enable --now nxapi-presence.service && ok "nxapi-presence actif"
else
  warn "Configurer ~/.config/nxapi/presence.env puis : systemctl --user enable --now nxapi-presence (docs/70-services.md)"
fi
