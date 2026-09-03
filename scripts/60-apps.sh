#!/usr/bin/env bash
# Phase 6 : applications. Utilisateur normal.
source "$(dirname "$0")/lib.sh"
load_config
need_user

install_pkgs "$REPO_DIR/pkgs/60-apps.txt"
stow_pkg apps
xdg-user-dirs-update
if command -v xdg-settings >/dev/null; then
  xdg-settings set default-web-browser brave-origin.desktop 2>/dev/null || warn "brave-origin.desktop introuvable"
  ok "Navigateur par defaut : $(xdg-settings get default-web-browser)"
fi
ok "Phase 6 terminee. Vesktop : activer Rich Presence (arRPC) dans ses parametres (utile pour nxapi, phase 7)."
