#!/usr/bin/env bash
# Phase 7 : nxapi (presence Switch -> Discord). Utilisateur normal.
source "$(dirname "$0")/lib.sh"
load_config
need_user

install_pkgs "$REPO_DIR/pkgs/70-services.txt"
# npm global dans ~/.local, sans sudo
npm config set prefix "$HOME/.local" >/dev/null
cur=$("$HOME/.local/bin/nxapi" --version 2>/dev/null | grep -oE '[0-9][0-9a-z.-]+' | head -1 || true)
if [[ "$cur" != "$NXAPI_VERSION" ]]; then
  info "npm install -g nxapi@$NXAPI_VERSION (actuel : ${cur:-aucun})"
  npm install -g "nxapi@$NXAPI_VERSION"
fi
stow_pkg nxapi
systemctl --user daemon-reload
if [[ -f "$HOME/.config/nxapi/presence.env" ]]; then
  systemctl --user enable --now nxapi-presence.service && ok "nxapi-presence actif"
else
  warn "Configurer ~/.config/nxapi/presence.env puis : systemctl --user enable --now nxapi-presence (docs/70-services.md)"
fi
