# 00 - Installation de base (Arch Linux + archinstall)

Le choix retenu : **archinstall avec une configuration versionnee** dans `archinstall/`,
completee par le script de post-installation du repo. Le fichier JSON sert de reference
reproductible ; archinstall reste interactif pour les points qu'il ne faut jamais figer
(choix du disque, mots de passe).

Pourquoi pas une installation 100 % manuelle : elle n'apporte rien de plus ici, puisque
tout ce qui rend la machine specifique (repos CachyOS, noyau, NVIDIA, Hyprland) se fait
de toute facon apres le premier boot, par `install.sh`.

> **Branche** : tant que le travail n'est pas fusionne dans `main`, cloner avec
> `git clone -b claude/hyprland-niri-config-mfqfg7 https://github.com/krier-julien/arch-dots`.
> Les commandes ci-dessous supposent `main` ; ajouter `-b <branche>` si besoin.

## 0. Deroule complet (resume)

| Etape | Ou | Commande | Redemarrage apres |
|-------|----|----------|-------------------|
| BIOS | UEFI | Secure Boot off, EXPO, CPPC Preferred Cores = Driver, ReBAR | |
| archinstall | live ISO | `archinstall --config ... --creds ...` | oui |
| Phase 1 | TTY, premier boot | `./install.sh 10` | **oui** (noyau CachyOS + NVIDIA) |
| Phase 2 | TTY | `./install.sh 20` | **oui** (SDDM, session Hyprland uwsm) |
| Phases 3 a 7 | terminal **dans Hyprland** | `./install.sh 30 40 50 60 70` | non (se deconnecter/reconnecter pour le groupe gamemode) |
| Validation | Hyprland | `docs/80-validation.md` | |

Compter environ 45 minutes hors telechargements. Les phases 4 et 7 redemarrent des services
utilisateur (PipeWire, nxapi) : elles doivent tourner depuis la session graphique, pas depuis
un TTY.

## 1. Preparer la cle USB

1. Telecharger l'ISO officielle Arch et la flasher (`dd`, Ventoy ou Rufus en mode DD).
2. BIOS MSI X670E Carbon :
   - Secure Boot desactive (necessaire pour les modules NVIDIA et le noyau CachyOS).
   - CSM desactive, boot UEFI uniquement.
   - EXPO profil 1 active (DDR5 6000 CL30).
   - `Advanced > AMD CBS > SMU > CPPC Dynamic Preferred Cores` sur `Driver` (laisse le noyau arbitrer les CCD).
   - Resizable BAR (Re-Size BAR Support) active.
3. Brancher un cable Ethernet, ou preparer `iwctl` pour le Wi-Fi.

## 2. Lancer archinstall

Sur le live ISO :

```bash
loadkeys us
pacman -Sy git               # archinstall est deja sur l'ISO
git clone https://github.com/krier-julien/arch-dots /tmp/arch-dots
cp /tmp/arch-dots/archinstall/user_credentials.json.example /tmp/creds.json
vim /tmp/creds.json          # mots de passe ; le nom d'utilisateur doit etre celui de DOTS_USER (config.env)
lsblk                        # identifier le NVMe cible
```

Adapter `device` dans `archinstall/user_configuration.json` si le disque n'est pas
`/dev/nvme0n1`, puis :

```bash
archinstall --config /tmp/arch-dots/archinstall/user_configuration.json \
            --creds  /tmp/creds.json
```

archinstall ouvre son menu avec les valeurs pre-remplies. Verifier surtout :

| Menu            | Valeur attendue                                            |
|-----------------|------------------------------------------------------------|
| Disk config     | ESP 1 GiB fat32 sur /boot, reste en btrfs, sous-volumes @, @home, @log, @pkg, @snapshots, compression zstd |
| Bootloader      | Limine                                                     |
| Kernels         | linux (le noyau CachyOS est ajoute apres, `linux` reste en secours) |
| Profile         | aucun (Hyprland est installe par le repo)                  |
| Network         | NetworkManager                                             |
| Swap            | desactive (zram configure par le repo)                     |

Si le format JSON de votre version d'archinstall differe et refuse le fichier (le champ
`version` est volontairement generique, archinstall avertit mais continue), re-saisir les
valeurs du tableau dans le menu, puis `Save configuration` et remplacer
`archinstall/user_configuration.json` par l'export. Ce fichier est la source de verite.

archinstall demande aussi le mot de passe root et l'utilisateur si `--creds` n'a pas ete
accepte : creer le meme utilisateur que `DOTS_USER`, membre de `wheel` (sudo).

Lancer l'installation, ne pas chrooter a la fin, redemarrer.

## 3. Premier boot : bootstrap

Se connecter en TTY avec l'utilisateur cree (pas root), puis :

```bash
sudo pacman -Syu git
git clone https://github.com/krier-julien/arch-dots ~/arch-dots
cd ~/arch-dots
cp config.env.example config.env && vim config.env   # DOTS_USER, hostname, moniteur, theme SDDM
./install.sh --list      # phases disponibles
./install.sh 10          # base : repos CachyOS, noyau, NVIDIA, Limine, snapper
sudo reboot              # obligatoire : noyau linux-cachyos + modules NVIDIA
```

Verifier `docs/10-base.md` (nvidia-smi, scx, x3d-mode), puis :

```bash
cd ~/arch-dots
./install.sh 20          # Hyprland, Caelestia, SDDM
sudo reboot              # SDDM -> session "Hyprland (uwsm-managed)"
```

Dans Hyprland, ouvrir un terminal (Super+T) :

```bash
cd ~/arch-dots
./install.sh 30 40 50 60 70
# puis : nxapi nso auth, ~/.config/nxapi/presence.env (docs/70-services.md)
# et Steam : options de lancement (docs/30-gaming.md)
```

Chaque phase est idempotente : relancer `install.sh` (sans argument, ou avec des numeros)
apres un `git pull` applique seulement ce qui a change. Une phase qui echoue s'arrete a
l'etape fautive ; corriger puis relancer la meme phase.

## 4. Rollback

`snap-pac` cree un snapshot avant et apres chaque transaction pacman et
`limine-snapper-sync` les expose dans le menu Limine. En cas de boot casse apres
une mise a jour : choisir le snapshot precedent dans Limine, puis
`sudo snapper rollback` une fois connecte.
