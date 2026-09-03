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
vm_lua=false; [[ "$DOTS_VM" == 1 ]] && vm_lua=true
cat > "$CFG/caelestia/local.lua" <<EOT
-- genere par scripts/20-hyprland.sh depuis config.env
return { monitor = "${DOTS_MONITOR}", vm = ${vm_lua}, bitdepth = ${DOTS_BITDEPTH} }
EOT
if [[ "$DOTS_VM" == 1 ]]; then
  cat > "$CFG/uwsm/env-local" <<'EOT'
# Mode VM : pas de pile NVIDIA
unset LIBVA_DRIVER_NAME __GLX_VENDOR_LIBRARY_NAME NVD_BACKEND
EOT
else
  rm -f "$CFG/uwsm/env-local"
fi

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
# Themes qylock (https://github.com/Darkkal44/qylock) : copie de tous les themes Qt6
QYLOCK_SRC="$HOME/.local/src/qylock"
if [[ -d "$QYLOCK_SRC/.git" ]]; then git -C "$QYLOCK_SRC" pull -q --ff-only || warn "qylock: pull impossible"
else mkdir -p "$(dirname "$QYLOCK_SRC")"; git clone -q --depth 1 https://github.com/Darkkal44/qylock "$QYLOCK_SRC"; fi
for t in "$QYLOCK_SRC"/themes/*/; do
  name=$(basename "$t")
  if [[ "$name" == clockwork ]]; then
    for v in "$t"*/; do sudo rsync -a --delete "$v" "/usr/share/sddm/themes/clockwork-$(basename "$v")/"; done
  else
    sudo rsync -a --delete "$t" "/usr/share/sddm/themes/$name/"
  fi
done
ok "Themes qylock installes dans /usr/share/sddm/themes (clockwork-orbital, pixel-night-city, ...)"
[[ -d "/usr/share/sddm/themes/$DOTS_SDDM_THEME" ]] || warn "Theme SDDM '$DOTS_SDDM_THEME' introuvable dans /usr/share/sddm/themes"
sudo mkdir -p /etc/sddm.conf.d
sed "s|@@THEME@@|$DOTS_SDDM_THEME|" "$REPO_DIR/templates/sddm.conf" | sudo tee /etc/sddm.conf.d/zz-arch-dots.conf >/dev/null
sudo systemctl enable sddm.service
[[ "$(getent passwd "$USER" | cut -d: -f7)" == "$(command -v fish)" ]] || chsh -s "$(command -v fish)"

# Portails : redemarrage pour prendre en compte Hyprland
systemctl --user daemon-reload 2>/dev/null || true

ok "Phase 2 terminee. Redemarrer, choisir la session 'Hyprland (uwsm-managed)' dans SDDM."
