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
cd /tmp/arch-dots
cp archinstall/user_credentials.json.example /tmp/creds.json
vim /tmp/creds.json          # mots de passe ; le nom d'utilisateur doit etre celui de DOTS_USER (config.env)
lsblk -o NAME,SIZE,MODEL     # identifier le disque cible (nvme0n1, vda en VM...)
```

archinstall exige des tailles de partition explicites (pas de « reste du disque ») : le
generateur lit la taille reelle du disque et ecrit un JSON valide pour la version courante
d'archinstall (ESP 1 GiB + Btrfs sur le reste, sous-volumes, snapper, Limine) :

```bash
python3 archinstall/gen-config.py --device /dev/nvme0n1 -o /tmp/config.json   # /dev/vda en VM
archinstall --config /tmp/config.json --creds /tmp/creds.json
```

Options : `--hostname`, `--keymap`, `--timezone`, `--lang` (defauts : arch, us,
Europe/Luxembourg, en_US). Le `archinstall/user_configuration.json` du repo est la sortie
du generateur pour le SN850X 1 To, a titre de reference.

archinstall ouvre son menu avec les valeurs pre-remplies. Verifier surtout :

| Menu            | Valeur attendue                                            |
|-----------------|------------------------------------------------------------|
| Disk config     | ESP 1 GiB fat32 sur /boot, reste en btrfs, sous-volumes @, @home, @log, @pkg, @snapshots, compression zstd |
| Bootloader      | Limine                                                     |
| Kernels         | linux (le noyau CachyOS est ajoute apres, `linux` reste en secours) |
| Profile         | aucun (Hyprland est installe par le repo)                  |
| Network         | NetworkManager                                             |
| Swap            | desactive (zram configure par le repo)                     |

Le format a ete cale sur le code d'archinstall 3.x (septembre 2026). Si une version future
refuse le fichier, re-saisir les valeurs du tableau dans le menu, puis `Save configuration`
et me transmettre l'export pour mettre a jour `gen-config.py`.

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

## 4. Deux NVMe (SN850X 1 To + 2 To) dans un seul Btrfs (~3 To)

archinstall ne cree pas de Btrfs multi-disques, mais Btrfs s'etend a chaud. Marche a suivre :

1. Installer avec archinstall sur le **1 To** (`device` = son chemin, verifier avec
   `lsblk -o NAME,SIZE,MODEL`). L'ESP et le Btrfs racine y vivent.
2. Au premier boot, dans `config.env` : `DOTS_BTRFS_EXTRA_DEVICE="/dev/nvme1n1"` (le 2 To)
   et `DOTS_BTRFS_WIPE=1` s'il contient encore quelque chose.
3. `./install.sh 10` ajoute le disque au Btrfs racine et lance un equilibrage
   `data=single, metadata=raid1`, puis regenere l'initramfs avec le hook `btrfs`.

Resultat : un seul systeme de fichiers d'environ 2,7 Tio utilisables (`btrfs filesystem df /`),
tous les sous-volumes, snapshots et le rollback Limine continuent de fonctionner. Les
metadonnees sont dupliquees sur les deux disques ; les donnees ne le sont pas (c'est ce qui
additionne les capacites) : **la perte d'un NVMe rend l'ensemble inutilisable**, comme un
RAID 0. Sauvegarder ce qui compte ailleurs (Steam se retelecharge).

Alternative si tu preferes isoler : garder le 2 To en Btrfs separe monte sur
`/home/<user>/Games` (bibliotheque Steam). Dans ce cas laisser `DOTS_BTRFS_EXTRA_DEVICE`
vide et monter le disque a la main via `/etc/fstab`.

Les deux disques ont le meme UUID Btrfs ; `/etc/fstab` n'a pas besoin de changer.

## 5. Tester en machine virtuelle

Oui, avec `DOTS_VM=1` dans `config.env` : les pilotes NVIDIA, le module de capteurs, les
parametres noyau NVIDIA et l'environnement `__GLX_VENDOR_LIBRARY_NAME` sont sautes, et
Hyprland utilise l'ecran virtuel en mode `preferred`.

Sur un hote Arch, `scripts/vm/create-test-vm.sh <archlinux.iso>` cree la VM complete avec
libvirt (prerequis listes en tete du script), puis `virt-viewer --attach arch-dots-test`.
Le disque d'installation est `/dev/vda`, le second `/dev/vdb`. Dans le `config.env` de la VM :
`DOTS_VM=1`, `DOTS_MONITOR="Virtual-1"`, `DOTS_BTRFS_EXTRA_DEVICE="/dev/vdb"`, et generer la
config archinstall avec `--device /dev/vda`.

Reglages equivalents si tu preferes virt-manager :

| Reglage | Valeur |
|---------|--------|
| Firmware | UEFI (OVMF, `x86_64 OVMF_CODE_4M.fd`, sans Secure Boot) |
| Chipset | Q35 |
| CPU | `host-passthrough`, 8 vCPU (le script CachyOS detecte alors znver4 comme sur l'hote) |
| RAM | 8 Go ou plus |
| Disques | 2 disques virtio (ex. 40 Go + 40 Go) pour tester l'ajout Btrfs du second |
| Video | `virtio` avec acceleration 3D, affichage Spice avec OpenGL (ou `virtio-vga-gl`) |
| Reseau | NAT par defaut |

Ce qui ne peut pas etre valide en VM : rendu NVIDIA, VRR/tearing/HDR, `x3d-mode` (pas de
driver amd_x3d_vcache), liquidctl, Elgato (sauf passthrough USB), performances de jeu.
Tout le reste l'est : archinstall avec le JSON, repos CachyOS, Limine + snapshots, Btrfs
multi-disques, Hyprland + Caelestia, workspaces et autostart, SDDM/qylock, PipeWire, nxapi.

Astuce : `virsh snapshot-create-as arch-dots-test post-archinstall` juste apres archinstall
permet de rejouer `install.sh 10` autant de fois que necessaire
(`virsh snapshot-revert arch-dots-test post-archinstall`).

Le premier `pacman -Syu` et `caelestia install` telechargent plusieurs Go : prevoir 40 Go
par disque et un cache pacman sur l'hote si tu rejoues souvent.

## 6. Rollback

`snap-pac` cree un snapshot avant et apres chaque transaction pacman et
`limine-snapper-sync` les expose dans le menu Limine. En cas de boot casse apres
une mise a jour : choisir le snapshot precedent dans Limine, puis
`sudo snapper rollback` une fois connecte.
