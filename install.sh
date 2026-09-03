#!/usr/bin/env bash
# Orchestrateur : lance les phases dans l'ordre. Chaque phase est idempotente.
#
#   ./install.sh            -> toutes les phases disponibles
#   ./install.sh 10 30      -> seulement les phases 10 et 30
#   ./install.sh --list     -> liste des phases
#
# Les phases marquees [root] relancent sudo elles-memes.
source "$(dirname "$0")/scripts/lib.sh"

usage() { sed -n '2,9p' "$0"; }
list_phases() { ls "$REPO_DIR"/scripts/[0-9][0-9]-*.sh 2>/dev/null | xargs -n1 basename; }

[[ "${1:-}" == "--help" ]] && { usage; exit 0; }
[[ "${1:-}" == "--list" ]] && { list_phases; exit 0; }

load_config
phases=()
if [[ $# -eq 0 ]]; then
  mapfile -t phases < <(list_phases)
else
  for n in "$@"; do
    f=$(ls "$REPO_DIR"/scripts/"$n"-*.sh 2>/dev/null | head -1) || true
    [[ -n "$f" ]] || die "Phase $n introuvable (voir --list)"
    phases+=("$(basename "$f")")
  done
fi

for p in "${phases[@]}"; do
  info "=== Phase $p ==="
  bash "$REPO_DIR/scripts/$p"
  ok "Phase $p terminee"
done
