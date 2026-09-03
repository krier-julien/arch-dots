#!/usr/bin/env bash
# Fonctions partagees par install.sh et les scripts de phase.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export REPO_DIR

# Couleurs
_c() { printf '\033[%sm' "$1"; }
info()  { printf '%s[info]%s %s\n'  "$(_c 34)" "$(_c 0)" "$*"; }
ok()    { printf '%s[ ok ]%s %s\n'  "$(_c 32)" "$(_c 0)" "$*"; }
warn()  { printf '%s[warn]%s %s\n'  "$(_c 33)" "$(_c 0)" "$*" >&2; }
die()   { printf '%s[fail]%s %s\n'  "$(_c 31)" "$(_c 0)" "$*" >&2; exit 1; }

load_config() {
  local f="$REPO_DIR/config.env"
  [[ -f "$f" ]] || die "config.env manquant. Copier config.env.example vers config.env et l'adapter."
  # shellcheck disable=SC1090
  source "$f"
  : "${DOTS_USER:?}" "${DOTS_HOSTNAME:?}" "${DOTS_TIMEZONE:?}" "${DOTS_LOCALE:?}" "${DOTS_KEYMAP:?}"
  : "${CACHYOS_ARCH_LEVEL:=znver4}" "${DOTS_MONITOR:=HDMI-A-1}" "${DOTS_SDDM_THEME:=sddm-astronaut-theme}" "${NXAPI_VERSION:=1.6.1-next.254}" "${DOTS_BTRFS_EXTRA_DEVICE:=}" "${DOTS_BTRFS_WIPE:=0}" "${DOTS_VM:=0}" "${DOTS_BITDEPTH:=10}" "${DOTS_LIMINE_DEFAULT_ENTRY:=Arch Linux/linux-cachyos}" "${DOTS_LIMINE_TIMEOUT:=3}" "${DOTS_NVIDIA_EARLY_KMS:=0}"
  export DOTS_USER DOTS_HOSTNAME DOTS_TIMEZONE DOTS_LOCALE DOTS_KEYMAP CACHYOS_ARCH_LEVEL DOTS_MONITOR DOTS_SDDM_THEME NXAPI_VERSION DOTS_BTRFS_EXTRA_DEVICE DOTS_BTRFS_WIPE DOTS_VM DOTS_BITDEPTH DOTS_LIMINE_DEFAULT_ENTRY DOTS_LIMINE_TIMEOUT DOTS_NVIDIA_EARLY_KMS
}

need_root()  { [[ $EUID -eq 0 ]] || die "Ce script doit etre lance en root (sudo)."; }
need_user()  { [[ $EUID -ne 0 ]] || die "Ce script doit etre lance en utilisateur normal, pas en root."; }
have()       { command -v "$1" >/dev/null 2>&1; }

# Lit une liste pkgs/*.txt en ignorant commentaires et lignes vides.
read_pkg_list() { grep -vE '^\s*(#|$)' "$1" | tr -d '\r'; }

# Paquets sans objet dans une VM (DOTS_VM=1) : pilotes NVIDIA, capteurs de la carte mere
VM_SKIP_REGEX='^(linux-cachyos-nvidia-open|nvidia-utils|lib32-nvidia-utils|nvidia-settings|libva-nvidia-driver|lib32-libva-nvidia-driver|nct6687d-dkms-git|nvtop)$'

# Installe une liste de paquets (repos + AUR) via paru, sans reinstaller ce qui est deja present.
install_pkgs() {
  local list="$1" missing=()
  have paru || die "paru est requis. Lancer d'abord scripts/10-base.sh."
  while read -r p; do
    [[ "${DOTS_VM:-0}" == 1 && "$p" =~ $VM_SKIP_REGEX ]] && continue
    pacman -Qq "$p" >/dev/null 2>&1 || missing+=("$p")
  done < <(read_pkg_list "$list")
  if [[ ${#missing[@]} -eq 0 ]]; then ok "Rien a installer pour $(basename "$list")"; return; fi
  info "Installation ($(basename "$list")) : ${missing[*]}"
  paru -S --needed --noconfirm "${missing[@]}"
}

# Copie system/ vers / en conservant les droits, avec sauvegarde .bak des fichiers modifies.
sync_system() {
  need_root
  info "Synchronisation system/ -> /"
  rsync -a --backup --suffix=.bak --chown=root:root "$REPO_DIR/system/" /
}

# Symlinke un paquet stow de dots/ vers $HOME.
stow_pkg() {
  need_user
  local pkg="$1"
  [[ -d "$REPO_DIR/dots/$pkg" ]] || { warn "dots/$pkg absent, ignore"; return; }
  info "stow $pkg"
  stow --no-folding --dir="$REPO_DIR/dots" --target="$HOME" --restow "$pkg"
}

# Active une unite systemd (system ou --user) sans echouer si deja active.
enable_unit() {
  local scope="$1" unit="$2"
  if [[ "$scope" == user ]]; then systemctl --user enable --now "$unit" || warn "Echec activation user $unit"
  else systemctl enable --now "$unit" || warn "Echec activation $unit"; fi
}
