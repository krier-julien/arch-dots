# arch-dots

Configuration complete d'un poste Arch Linux + CachyOS + Hyprland, oriente jeu et capture.

**Materiel cible** : Ryzen 9 7950X3D, RTX 4090, MSI X670E Carbon WiFi, 64 Go DDR5 6000,
LG G3 55" (4K 120 Hz, VRR, scale 2.0), NZXT Kraken Elite, 10 Lian Li Uni Fan SL V2,
Elgato 4K X.

- Plan et etat d'avancement : [docs/PLAN.md](docs/PLAN.md)
- Installation : [docs/00-install.md](docs/00-install.md), puis un guide par phase dans `docs/`
- Validation finale : [docs/80-validation.md](docs/80-validation.md)

## Utilisation rapide

```bash
git clone https://github.com/krier-julien/arch-dots ~/arch-dots
cd ~/arch-dots
cp config.env.example config.env   # puis editer
./install.sh --list
./install.sh                       # toutes les phases, idempotent
```

Les dotfiles sont geres avec GNU stow (`dots/`), les fichiers systeme sont dans `system/`
et copies vers `/`. Aucun secret n'est versionne (voir `.gitignore`).
