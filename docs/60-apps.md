# 60 - Applications

Script : `scripts/60-apps.sh` (`./install.sh 60`).

| App | Paquet | Notes |
|-----|--------|-------|
| Brave Origin | `brave-origin-bin` | Navigateur par defaut (`mimeapps.list` + `xdg-settings`). Flags Wayland + VA-API dans `~/.config/brave-origin-flags.conf` (verifier que le wrapper les lit : `cat /usr/bin/brave-origin`) |
| Vesktop | `vesktop` | Discord le plus stable sous Wayland : partage d'ecran via le portail Hyprland, arRPC integre. Flags dans `vesktop-flags.conf` et `electron-flags.conf` |
| Pear Desktop | `pear-desktop-bin` | YouTube Music. Classe `com.github.th-ch.youtube-music`, workspace 5 |
| Plezy | `plezy-bin` | Client Plex (Flutter), classe `com.edde746.plezy`, workspace 6 |
| Steam, OBS, ProtonPlus | phases 3 et 4 | |

## Vesktop : reglages conseilles

- Parametres Vesktop > *Rich Presence* : activer arRPC (necessaire pour nxapi, phase 7).
- Parametres Vesktop > *Screen sharing* : audio partage via PipeWire (venmic) fonctionne
  nativement avec Hyprland.
- Le theming Caelestia (`cli.json`, `enableDiscord`) applique la palette a Vesktop.

## Flags Electron

`~/.config/electron-flags.conf` (et les alias `electronNN-flags.conf`) activent Wayland natif
et `WaylandLinuxDrmSyncobj` pour toutes les apps Electron utilisant l'electron systeme. Les
paquets `-bin` embarquant leur propre Electron lisent leur fichier dedie
(`vesktop-flags.conf`, `brave-origin-flags.conf`) ou `ELECTRON_OZONE_PLATFORM_HINT=auto`
deja exporte par uwsm.
