# 30 - Gaming : Steam, MangoHUD, gamemode, ntsync, V-Cache

Script : `scripts/30-gaming.sh` (`./install.sh 30`). Se deconnecter/reconnecter apres
(groupe `gamemode`).

## Options de lancement Steam (par jeu)

Clic droit sur le jeu > Proprietes > Options de lancement :

```
gamemoderun mangohud %command%
```

- `gamemoderun` : priorites, inhibition du verrouillage, et surtout bascule le 7950X3D en
  mode V-Cache (`x3d-mode cache`) pendant la partie, retour en mode frequence a la fin
  (`~/.config/gamemode.ini`, section `[custom]`).
- `mangohud` : HUD + cap a 117 FPS (`~/.config/MangoHud/MangoHud.conf`).

Variantes utiles :

```
PROTON_USE_NTSYNC=1 gamemoderun mangohud %command%   # forcer ntsync si Proton ne l'active pas seul
MANGOHUD_CONFIG=no_display gamemoderun mangohud %command%   # cap FPS sans HUD visible
gamemoderun mangohud gamescope -W 3840 -H 2160 -r 120 --hdr-enabled -f -- %command%   # HDR via gamescope
```

Le HUD est **masque au lancement** (`no_display=1`) mais le cap a 117 FPS s'applique quand meme.
Raccourcis en jeu :

| Touches | Action |
|---------|--------|
| `Shift_L + \`` | afficher / masquer le HUD (layout complet : FPS, 1 % low, frametime, GPU, CPU, RAM, winesync) |
| `Shift_L + F3` | cycler les presets : perso, FPS seul, ligne compacte, etendu, detaille |
| `Shift_L + F1` | cycler la limite : 117, illimitee, 60 |
| `Shift_L + F2` | demarrer / arreter l'enregistrement des frametimes |

Dans le jeu : **V-Sync desactive** (le VRR + cap 117 s'en chargent), plein ecran exclusif ou
sans bordure, 3840x2160.

## V-Cache automatique

Deux mecanismes redondants, tous deux idempotents :

1. gamemode (`[custom] start/end`) pour tout ce qui est lance avec `gamemoderun`.
2. Hyprland (`~/.config/caelestia/gaming.lua`) : a l'ouverture d'une fenetre `steam_app_*`
   ou `gamescope`, `x3d-mode cache` ; a la fermeture du dernier jeu, `x3d-mode frequency`.

Verifier : `x3d-mode` dans un terminal pendant une partie doit repondre `cache`.
Prerequis BIOS : `CPPC Dynamic Preferred Cores = Driver` (sinon le driver n'existe pas).

## Scaling 2.0 : interface Steam et overlay

- L'interface Steam (client Xwayland) est mise a l'echelle par `STEAM_FORCE_DESKTOPUI_SCALING=2`,
  exporte pour toute la session dans `~/.config/uwsm/env` (Phase 2). Avec
  `xwayland.force_zero_scaling`, le client est rendu en 2x natif, donc net.
- L'overlay en jeu (Shift+Tab) est rendu par le client Steam avec le meme facteur : il
  suit donc `STEAM_FORCE_DESKTOPUI_SCALING`. Si tu veux le forcer par jeu :

  ```
  STEAM_FORCE_DESKTOPUI_SCALING=2 gamemoderun mangohud %command%
  ```

  Si l'overlay reste trop petit dans un jeu precis, verifier dans Steam >
  Parametres > En jeu que l'overlay est active pour ce jeu et que l'echelle de l'interface
  (Parametres > Interface > *Mise a l'echelle*) est sur Automatique.
- Big Picture / mode TV : `steam -gamepadui` utilise sa propre echelle 4K et n'a besoin de rien.

## ntsync

Le noyau CachyOS fournit `ntsync` (>= 6.14). La phase charge le module au boot et rend
`/dev/ntsync` lisible. Proton 10+ et GE-Proton l'utilisent automatiquement quand le
peripherique existe ; sinon `PROTON_USE_NTSYNC=1`.

Verifier qu'un jeu l'utilise :

```bash
ls -l /dev/ntsync                                   # crw-r--r-- root root
pid=$(pgrep -f 'steam_app_' | head -1)              # ou le pid du .exe
ls -l /proc/$pid/fd | grep ntsync                   # une entree = ntsync actif
# ou via MangoHUD : la ligne "winesync" affiche ntsync / fsync / esync
```

## Manette Xbox avec le dongle Xbox Wireless

Le dongle officiel n'est pas pris en charge par le noyau : la phase installe `xone-dkms-git`
(driver, compile par DKMS pour les deux noyaux) et `xone-dongle-firmware` (firmware du dongle,
telecharge chez Microsoft). xone remplace `xpad` pour ces peripheriques.

Verifier :

```bash
dkms status                          # xone ... installed pour 7.x-cachyos et 7.x-arch1
lsmod | grep -E 'xone|xpad'          # xone_dongle, xone_gip ; pas de xpad
# brancher le dongle, appuyer sur le bouton d'association du dongle puis de la manette
ls /dev/input/js* ; evtest           # la manette apparait
```

Steam > Parametres > Manette : activer *Prise en charge Xbox* ; le Steam Input s'occupe du
reste. En jeu, les vibrations et la prise casque de la manette sont geres par xone.

Mise a jour du noyau : DKMS recompile xone automatiquement (paquets headers installes).

## ProtonPlus

`protonplus` (GUI GTK) installe et met a jour GE-Proton, Proton-CachyOS, Luxtorpeda, etc.
dans `~/.local/share/Steam/compatibilitytools.d`. Apres installation : redemarrer Steam,
puis Proprietes du jeu > Compatibilite > choisir la version. Proton-CachyOS est compile pour
znver4 et active ntsync par defaut.

## VRR, tearing, direct scanout : verification en jeu

```bash
hyprctl monitors | grep -E 'vrr|activelyTearing|tearingBlockedBy|directScanoutTo|directScanoutBlockedBy'
```

Attendu en plein ecran : `vrr: true`, `directScanoutTo` non nul. `activelyTearing: true`
seulement si le jeu depasse 120 FPS (cap a 117 : normalement `false`, ce qui est voulu ;
passer en illimite avec `Shift_L+F1` pour tester).
