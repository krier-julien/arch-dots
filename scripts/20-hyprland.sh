#!/usr/bin/env bash
# Phase 2 : Hyprland + rice Caelestia + SDDM. A lancer en utilisateur normal.
source "$(dirname "$0")/lib.sh"
load_config
need_user
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"

# --- 1. Paquets (Hyprland, portails, SDDM, CLI/shell Caelestia) -----------------------
install_pkgs "$REPO_DIR/pkgs/20-hyprland.txt"

# --- 2. Nos overrides d'abord : Caelestia ne touche jamais ~/.config/caelestia/* ------
stow_pkg caelestia
stow_pkg uwsm
# Valeurs locales lues par hypr-user.lua (non versionnees)
cat > "$CFG/caelestia/local.lua" <<EOT
-- genere par scripts/20-hyprland.sh depuis config.env
return { monitor = "${DOTS_MONITOR}" }
EOT

# --- 3. Dotfiles Caelestia (hypr, foot, fish, btop, fastfetch, thunar, gtk/qt, auth...) --
# Composants desactives : navigateur/discord/editeurs geres par nos phases 6, uwsm gere par
# notre paquet stow (evite le conflit sur ~/.config/uwsm/env).
DISABLED="firefox,zen,discord,spotify,vscode,vscodium,zed,nvim,todoist,uwsm"
if [[ ! -f "$CFG/hypr/hyprland.lua" ]]; then
  info "caelestia install (composants desactives : $DISABLED)"
  caelestia install --aur-helper paru --noconfirm --disable-components "$DISABLED"
else
  ok "Dots Caelestia deja en place. Mise a jour : caelestia update --noconfirm"
fi
[[ -L "$CFG/caelestia/hypr-user.lua" ]] || warn "hypr-user.lua n'est plus un symlink vers le repo"

# --- 4. Session : SDDM + uwsm, fish par defaut ----------------------------------------
sudo rsync -a --backup --suffix=.bak --chown=root:root "$REPO_DIR/system/etc/sddm.conf.d" /etc/
sudo systemctl enable sddm.service
[[ "$(getent passwd "$USER" | cut -d: -f7)" == "$(command -v fish)" ]] || chsh -s "$(command -v fish)"

# Portails : redemarrage pour prendre en compte Hyprland
systemctl --user daemon-reload 2>/dev/null || true

ok "Phase 2 terminee. Redemarrer, choisir la session 'Hyprland (uwsm-managed)' dans SDDM."
