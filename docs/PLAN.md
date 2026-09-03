# Plan d'action

Decisions prises :

- **OS** : Arch Linux + repos et noyau CachyOS (tier znver4), Btrfs + snapper + Limine.
- **Compositeur** : Hyprland (Niri pourra etre ajoute plus tard comme paquet stow separe).
- **Rice** : base Caelestia (Quickshell), palette dynamique.
- **Installation** : archinstall avec config versionnee + `install.sh` post-install.
- **Materiel** : NZXT Kraken Elite (pompe + LCD) et 10 Lian Li Uni Fan SL V2 sur hub Uni,
  tous pilotes par liquidctl >= 1.16.0 (driver `lianli_uni`). Vitesses **fixes** pour la
  pompe et les ventilateurs (decision utilisateur : le boitier est tres ventile), appliquees
  par un service systemd au boot. Pas de demon de courbes.
- **Bureau** : workspaces fixes 1 Brave, 2 Discord, 3 Steam, 4 OBS, 5 YouTube Music, 6 Plezy, 7 jeux ; autostart des six premiers ; verrouillage a 15 min, jamais d'extinction d'ecran ni de veille ; themes SDDM astronaut ou qylock.
- **Identite** : hostname `arch`, fuseau Europe/Luxembourg, clavier US, systeme en anglais
  avec formats europeens (en_GB) et monnaie EUR (de_LU).

| Phase | Contenu | Script | Etat |
|-------|---------|--------|------|
| 0 | Squelette du repo, listes de paquets, config archinstall, docs | - | fait |
| 1 | Repos CachyOS, `linux-cachyos`, nvidia-open, parametres noyau, sched-ext (`scx_lavd`), zram, snapper, nct6687d, bascule V-Cache 7950X3D | `scripts/10-base.sh`, `docs/10-base.md` | fait |
| 2 | Hyprland : moniteur 4K@120 scale 2, VRR plein ecran, tearing, env NVIDIA, Xwayland HiDPI, portails, SDDM, shell Caelestia | `scripts/20-hyprland.sh`, `dots/caelestia`, `dots/uwsm`, `docs/20-hyprland.md` | fait |
| 3 | Steam (scaling UI + overlay), MangoHUD cap 117, gamemode + V-Cache auto, ntsync, ProtonPlus | `scripts/30-gaming.sh`, `dots/gaming`, `docs/30-gaming.md` | fait |
| 4 | udev Elgato 4K X, noeud audio stable + loopback PipeWire persistant, profil OBS NVENC | `scripts/40-media.sh`, `dots/media`, `templates/obs-profile`, `docs/40-media.md` | fait |
| 5 | liquidctl : vitesses fixes pompe Kraken et hub Lian Li, service systemd | `scripts/50-hardware.sh`, `system/etc/liquidctl` | a faire |
| 6 | brave-origin par defaut, Vesktop Wayland, Pear-desktop, Plezy | `scripts/60-apps.sh`, `dots/apps` | a faire |
| 7 | Service utilisateur nxapi (compte Nintendo secondaire), secrets hors repo | `scripts/70-services.sh`, `dots/nxapi` | a faire |
| 8 | Checklist de validation | `docs/80-validation.md` | a faire |

## Arborescence

```
arch-dots/
├── install.sh              orchestrateur des phases
├── config.env.example      variables locales (user, hostname, ecran...)
├── archinstall/            config archinstall versionnee
├── pkgs/NN-*.txt           listes de paquets par phase (repos + AUR)
├── scripts/NN-*.sh         scripts de phase idempotents, scripts/lib.sh partage
├── system/                 fichiers root, copies vers / par rsync (etc/, usr/local/bin/)
├── templates/              fichiers generes avec substitution (Limine)
├── dots/<paquet>/          dotfiles, symlinkes vers ~ par GNU stow
└── docs/                   guides par phase
```
