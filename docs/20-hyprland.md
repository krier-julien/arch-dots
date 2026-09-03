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
| `shell.json` | Shell : apps, idle (verrouillage a 15 min, jamais d'extinction d'ecran ni de veille), meteo, 24 h |
| `workspaces.lua` | Workspaces fixes 1..7 lies a la TV, regles par application, autostart |
| `gaming.lua` | V-Cache automatique a l'ouverture/fermeture d'un jeu |
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

## Workspaces fixes et autostart

| WS | Application | Classe attendue | Autostart |
|----|-------------|-----------------|-----------|
| 1 | Brave Origin | `brave-browser` / `brave-origin` | oui |
| 2 | Vesktop (Discord) | `vesktop` | oui |
| 3 | Steam et toutes ses fenetres | `steam` | oui |
| 4 | OBS Studio | `com.obsproject.Studio` | oui |
| 5 | Pear Desktop (YouTube Music) | `pear-desktop` / `com.github.th_ch.youtube_music` | oui |
| 6 | Plezy | `plezy` | oui |
| 7 | Jeux (Steam, gamescope) | `steam_app_*`, `gamescope` | a la demande |

Les fenetres des apps 1..6 sont envoyees sur leur workspace en mode `silent` (sans voler le
focus), les jeux prennent le workspace 7 avec le focus. Les 7 workspaces sont `persistent`
et lies a la TV. Si une classe differe sur ta machine (`hyprctl clients`), corriger
`workspaces.lua` : c'est la seule source de verite pour les classes et l'autostart.

## TV eteinte pendant le verrouillage

L'ecran n'est jamais eteint par le shell. Si la TV s'eteint seule (minuterie LG) alors que la
session est verrouillee :

- Hyprland cree une sortie headless de secours quand plus aucun ecran n'est connecte, puis
  rapplique la regle `hl.monitor` quand la G3 revient. Les workspaces lies a la TV y reviennent.
- `misc.allow_session_lock_restore = true` (Caelestia) recree l'ecran de verrouillage.
- Les evenements `monitor.added/removed` sont journalises (`journalctl --user -t hyprland`).

Reglage conseille sur la TV : desactiver *Extinction automatique / No Signal Off* dans les
options d'economie d'energie, ou l'allonger au maximum.

## SDDM

Theme choisi par `DOTS_SDDM_THEME` dans `config.env` : `sddm-astronaut-theme` (AUR) ou l'un
des themes [qylock](https://github.com/Darkkal44/qylock) que le script copie dans
`/usr/share/sddm/themes` : `material-you`, `pixel-night-city`, `pixel-cyberpunk`,
`nier-automata`, `clockwork-orbital`, `clockwork-tape`, `clockwork-neo-brutalism`,
`star-rail`, `terraria`, `minecraft`, `windows_7`... (`ls /usr/share/sddm/themes`).
Certains themes attendent une police non distribuee (voir le README de qylock, dossier
`font/` du theme). Tester sans redemarrer :

```bash
sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/pixel-night-city
```

Greeter X11 en 192 dpi. Au premier login, choisir la session **Hyprland (uwsm-managed)**
(icone de session, en bas a gauche) ; SDDM la retient ensuite.

## Raccourcis ajoutes

- `Super + Shift + G` : bascule manuelle V-Cache / frequence du 7950X3D. L'automatique (jeu ouvert = cache) est dans `gaming.lua` et dans gamemode (Phase 3).
- Le reste : voir le README de Caelestia (Super seul = lanceur, Super+T terminal, Super+W
  navigateur, Super+E fichiers, Super+L verrouillage).

## Fond d'ecran et palette

```bash
caelestia wallpaper -f ~/Pictures/Wallpapers/mon-image.png   # palette generee automatiquement
caelestia scheme set -n catppuccin  # ou un autre scheme
```
