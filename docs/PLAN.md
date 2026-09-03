# Plan d'action

Decisions prises :

- **OS** : Arch Linux + repos et noyau CachyOS (x86-64-v4), Btrfs + snapper + Limine.
- **Compositeur** : Hyprland (Niri pourra etre ajoute plus tard comme paquet stow separe).
- **Rice** : base Caelestia (Quickshell), palette dynamique.
- **Installation** : archinstall avec config versionnee + `install.sh` post-install.
- **Materiel** : NZXT Kraken Elite (pompe + LCD) et 10 Lian Li Uni Fan SL V2 sur hub Uni,
  tous pilotes par liquidctl >= 1.16.0 (driver `lianli_uni`). Le hub ne stocke pas de
  courbe : un demon du repo lit les temperatures et pousse les duty cycles.

| Phase | Contenu | Script | Etat |
|-------|---------|--------|------|
| 0 | Squelette du repo, listes de paquets, config archinstall, docs | - | fait |
| 1 | Repos CachyOS, `linux-cachyos`, nvidia-open, parametres noyau, sched-ext (`scx_lavd`), zram, snapper, nct6687d, bascule V-Cache 7950X3D | `scripts/10-base.sh` | a faire |
| 2 | Hyprland : moniteur 4K@120 scale 2, VRR plein ecran, tearing, env NVIDIA, Xwayland HiDPI, portails, SDDM, shell Caelestia | `scripts/20-hyprland.sh`, `dots/hypr`, `dots/caelestia` | a faire |
| 3 | Steam (scaling UI + overlay), MangoHUD cap 117, gamemode + V-Cache, ProtonPlus | `scripts/30-gaming.sh`, `dots/gaming` | a faire |
| 4 | udev Elgato 4K X, loopback PipeWire persistant, profil OBS NVENC | `scripts/40-media.sh`, `dots/pipewire`, `dots/obs` | a faire |
| 5 | liquidctl : profil pompe Kraken, demon de courbes Lian Li, services systemd | `scripts/50-hardware.sh`, `system/etc/liquidctl` | a faire |
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
├── system/                 fichiers root, copies vers / par rsync (etc/...)
├── dots/<paquet>/          dotfiles, symlinkes vers ~ par GNU stow
└── docs/                   guides par phase
```
