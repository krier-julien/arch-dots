#!/usr/bin/env bash
# Phase 1 : base systeme. A lancer en utilisateur normal (sudo est demande au besoin).
# Idempotent : chaque etape verifie son etat avant d'agir.
source "$(dirname "$0")/lib.sh"
load_config
need_user
have sudo || die "sudo requis"
SCRATCH="${XDG_RUNTIME_DIR:-/tmp}/arch-dots-base"; mkdir -p "$SCRATCH"

# --- 1. pacman : multilib + repos CachyOS -------------------------------------------
if ! grep -qE '^\[multilib\]' /etc/pacman.conf; then
  info "Activation de [multilib]"
  sudo sed -i '/^#\[multilib\]/{s/^#//;n;s/^#//}' /etc/pacman.conf
fi
if ! grep -q '^\[cachyos' /etc/pacman.conf; then
  info "Ajout des repos CachyOS (script officiel, detection CPU -> attendu : $CACHYOS_ARCH_LEVEL)"
  ( cd "$SCRATCH" && curl -fsSLO https://mirror.cachyos.org/cachyos-repo.tar.xz \
      && tar xf cachyos-repo.tar.xz && cd cachyos-repo && sudo ./cachyos-repo.sh )
  grep -q "^\[cachyos-${CACHYOS_ARCH_LEVEL}\]" /etc/pacman.conf \
    || warn "Le tier $CACHYOS_ARCH_LEVEL n'a pas ete retenu par cachyos-repo.sh, verifier /etc/pacman.conf"
fi
sudo pacman -Syu --needed --noconfirm paru

# --- 2. Paquets -----------------------------------------------------------------------
install_pkgs "$REPO_DIR/pkgs/10-base.txt"

# --- 3. Fichiers systeme (modprobe, mkinitcpio, scx, zram, sysctl, x3d-mode) ---------
sudo rsync -a --backup --suffix=.bak --chown=root:root "$REPO_DIR/system/" /
sudo chmod 0440 /etc/sudoers.d/10-x3d-mode
sudo chmod 0755 /usr/local/bin/x3d-mode
sudo visudo -cf /etc/sudoers.d/10-x3d-mode >/dev/null || die "sudoers.d/10-x3d-mode invalide"

# --- 4. Identite : hostname, fuseau, locale, clavier ---------------------------------
[[ "$(hostnamectl hostname)" == "$DOTS_HOSTNAME" ]] || sudo hostnamectl set-hostname "$DOTS_HOSTNAME"
[[ "$(timedatectl show -p Timezone --value)" == "$DOTS_TIMEZONE" ]] || sudo timedatectl set-timezone "$DOTS_TIMEZONE"
for loc in "$DOTS_LOCALE" "${DOTS_LOCALE_FORMATS:-$DOTS_LOCALE}" "${DOTS_LOCALE_MONETARY:-$DOTS_LOCALE}" fr_FR.UTF-8; do
  sudo sed -i "s/^#\s*${loc} UTF-8/${loc} UTF-8/" /etc/locale.gen
done
sudo tee /etc/locale.conf >/dev/null <<EOT
LANG=${DOTS_LOCALE}
LC_TIME=${DOTS_LOCALE_FORMATS:-$DOTS_LOCALE}
LC_PAPER=${DOTS_LOCALE_FORMATS:-$DOTS_LOCALE}
LC_MEASUREMENT=${DOTS_LOCALE_FORMATS:-$DOTS_LOCALE}
LC_MONETARY=${DOTS_LOCALE_MONETARY:-$DOTS_LOCALE}
EOT
sudo locale-gen >/dev/null
echo "KEYMAP=${DOTS_KEYMAP}" | sudo tee /etc/vconsole.conf >/dev/null
sudo usermod -aG wheel,input,video,gamemode "$DOTS_USER" 2>/dev/null || sudo usermod -aG wheel,input,video "$DOTS_USER"

# --- 5. Limine : cmdline noyau + entrees generees + snapshots ------------------------
# Le root= courant vient de /proc/cmdline (archinstall l'a ecrit dans limine.conf).
ROOT_ARGS=$(tr ' ' '\n' < /proc/cmdline | grep -E '^(root=|rootflags=|rootfstype=|rw$|resume=)' | tr '\n' ' ' | sed 's/ $//')
[[ -n "$ROOT_ARGS" ]] || die "Impossible de determiner root= depuis /proc/cmdline"
sed "s|@@ROOT@@|$ROOT_ARGS|" "$REPO_DIR/templates/limine.default" | sudo tee /etc/default/limine >/dev/null
ok "/etc/default/limine ecrit (root: $ROOT_ARGS)"

# Un seul limine.conf, a /boot/limine.conf, avec notre entete ; limine-update ajoute les entrees.
for c in /boot/EFI/arch-limine/limine.conf /boot/EFI/BOOT/limine.conf /boot/EFI/limine/limine.conf /boot/limine/limine.conf; do
  [[ -f "$c" ]] && { info "Deplacement $c -> /boot/limine.conf"; sudo mv -f "$c" /boot/limine.conf; }
done
if ! grep -q '^### Entete Limine gere par arch-dots' /boot/limine.conf 2>/dev/null; then
  [[ -f /boot/limine.conf ]] && sudo cp /boot/limine.conf /boot/limine.conf.archinstall.bak
  sudo cp "$REPO_DIR/templates/limine.conf" /boot/limine.conf
fi
# limine-mkinitcpio-hook lit /etc/default/limine a l'installation : l'ordre compte.
sudo pacman -S --needed --noconfirm limine-mkinitcpio-hook limine-snapper-sync
sudo mkinitcpio -P
sudo limine-update
grep -q '^/+' /boot/limine.conf || die "limine-update n'a genere aucune entree dans /boot/limine.conf"

# --- 6. snapper : config root (archinstall a pu la creer) ----------------------------
if ! sudo snapper list-configs 2>/dev/null | grep -q '^root'; then
  info "Creation de la config snapper root"
  sudo umount /.snapshots 2>/dev/null || true
  sudo rm -rf /.snapshots
  sudo snapper -c root create-config /
  sudo btrfs subvolume delete /.snapshots
  sudo mkdir /.snapshots
  sudo mount -a
  sudo chmod 750 /.snapshots
fi
sudo sed -i -e 's/^TIMELINE_CREATE=.*/TIMELINE_CREATE="no"/' \
            -e 's/^NUMBER_LIMIT=.*/NUMBER_LIMIT="10"/' \
            -e 's/^NUMBER_LIMIT_IMPORTANT=.*/NUMBER_LIMIT_IMPORTANT="5"/' \
            -e "s/^ALLOW_USERS=.*/ALLOW_USERS=\"$DOTS_USER\"/" /etc/snapper/configs/root
sudo btrfs quota disable / 2>/dev/null || true   # les qgroups coutent cher en perfs

# --- 7. Services ----------------------------------------------------------------------
sudo systemctl daemon-reload
for u in NetworkManager bluetooth fstrim.timer systemd-timesyncd ananicy-cpp scx \
         nvidia-suspend nvidia-hibernate nvidia-resume snapper-cleanup.timer limine-snapper-sync; do
  sudo systemctl enable --now "$u" 2>/dev/null || sudo systemctl enable "$u" || warn "unite $u absente"
done
sudo systemctl start systemd-zram-setup@zram0.service 2>/dev/null || true

ok "Phase 1 terminee. Redemarrer sur le noyau linux-cachyos puis verifier avec docs/10-base.md"
