# 20 - Hyprland, rice Caelestia, SDDM

Script : `scripts/20-hyprland.sh` (`./install.sh 20`).

## Principe

Caelestia est installe par son propre CLI (`caelestia install`), qui gere `~/.config/hypr`,
foot, fish, btop, le shell Quickshell, le theming GTK/Qt et la palette dynamique. Sa regle :
**ne jamais modifier `~/.config/hypr/`**. Tout ce qui nous est propre vit donc dans
`~/.config/caelestia/`, symlinke depuis `dots/caelestia/` :

| Fichier | Role |
|---------|------|
| `hypr-vars.lua` | Variables Caelestia : apps par defaut, curseur Bibata, gaps adaptes a la TV |
| `hypr-user.lua` | Moniteur, rendu (VRR, tearing, direct scanout), env NVIDIA, regles de fenetres |
| `shell.json` | Shell : apps, idle (lock 15 min, ecran off 30 min, pas de veille), meteo, 24 h |
| `cli.json` | Theming actif : terminal, Hyprland, Discord (Vesktop), GTK, Qt, btop, nvtop |
| `user-config.fish` | Fish perso |
| `local.lua` | genere depuis `config.env` (nom du moniteur), non versionne |

`dots/uwsm/` fournit l'environnement de session (NVIDIA, HiDPI, backends Wayland) applique
par uwsm a toutes les apps, y compris celles lancees par le shell.

## Ecran LG G3 : choix

| Reglage | Valeur | Raison |
|---------|--------|--------|
| Mode | 3840x2160@120, scale 2 | Bureau 1920x1080 logique, net a 3 m |
| `vrr` moniteur + `misc.vrr` | 2 | VRR seulement en plein ecran : pas de flicker OLED sur le bureau |
| `general.allow_tearing` | true | Le tag `game` de Caelestia porte deja `immediate` |
| `render.direct_scanout` | 2 | Scanout direct pour les fenetres avec content type `game` (regle ajoutee pour `steam_app_*`, gamescope) |
| `cursor.min_refresh_rate` | 48 | Plage VRR de la G3 |
| `xwayland.force_zero_scaling` + `GDK_SCALE=2` | | Xwayland net, GTK X11 a l'echelle ; Steam via `STEAM_FORCE_DESKTOPUI_SCALING=2` |
| `bitdepth`, `cm` | commentes | 10 bits et HDR permanent possibles, a activer apres test (`cm_auto_hdr` bascule deja en plein ecran) |

Verifier apres connexion :

```bash
hyprctl monitors        # scale 2.00, vrr, availableModes contient 3840x2160@120.00Hz
# en jeu plein ecran :
hyprctl monitors | grep -E 'vrr|activelyTearing|directScanoutTo|tearingBlockedBy'
```

## SDDM

Theme `sddm-astronaut-theme`, greeter X11 en 192 dpi. Au premier login, choisir la session
**Hyprland (uwsm-managed)** (icone de session, en bas a gauche) ; SDDM la retient ensuite.

## Raccourcis ajoutes

- `Super + Shift + G` : bascule V-Cache / frequence du 7950X3D avec notification.
- Le reste : voir le README de Caelestia (Super seul = lanceur, Super+T terminal, Super+W
  navigateur, Super+E fichiers, Super+L verrouillage).

## Fond d'ecran et palette

```bash
caelestia wallpaper -f ~/Pictures/Wallpapers/mon-image.png   # palette generee automatiquement
caelestia scheme set -n catppuccin  # ou un autre scheme
```
