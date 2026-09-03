# 10 - Base systeme : CachyOS, noyau, NVIDIA, Limine, snapper

Script : `scripts/10-base.sh` (`./install.sh 10`). Redemarrer ensuite.

## Ce que fait la phase

| Sujet | Choix | Pourquoi |
|-------|-------|----------|
| Repos | CachyOS tier **znver4** via `cachyos-repo.sh` | Paquets compiles pour Zen 4 (AVX-512), detection automatique du CPU |
| Noyau | `linux-cachyos` (BORE + sched-ext), `linux` conserve en secours | Rollback simple si une version CachyOS pose probleme |
| NVIDIA | `linux-cachyos-nvidia-open` + `nvidia-utils` ; KMS precoce optionnel (`DOTS_NVIDIA_EARLY_KMS`, defaut 0) | Modules open = choix NVIDIA pour Ada, HDMI 2.1 4K120 VRR gere par le firmware GSP |
| Scheduler | `scx_lavd --autopilot` via notre `scx.service` (le paquet `scx-scheds` ne fournit plus d'unite), config `/etc/default/scx` | Conscient des 2 CCD heterogenes du 7950X3D, faible latence |
| V-Cache | `/usr/local/bin/x3d-mode cache|frequency` (sudo sans mot de passe pour wheel) | gamemode basculera en `cache` au lancement d'un jeu (Phase 3) |
| Priorites | `ananicy-cpp` + regles CachyOS | Nice/ionice automatiques pour jeux, compilateurs, navigateurs |
| Memoire | zram 16 Go zstd, `zswap` desactive | 64 Go de RAM : pas de swap disque |
| Boot | Limine + `limine-entry-tool` (`/etc/default/limine`) + `limine-snapper-sync` | Parametres noyau versionnes, snapshots bootables dans le menu |
| Snapshots | snapper root, `snap-pac` avant/apres pacman, 10 snapshots, pas de timeline | Rollback de mise a jour sans bruit |
| Capteurs | `nct6687d-dkms-git` charge au boot | Puce NCT6687D des MSI X670E, sinon `sensors` est vide |
| Stockage | `DOTS_BTRFS_EXTRA_DEVICE` ajoute un second NVMe au Btrfs racine (data single, metadata raid1), hook mkinitcpio `btrfs` | ~3 To en un seul systeme de fichiers, voir docs/00-install.md |
| VM | `DOTS_VM=1` saute NVIDIA, nct6687 et les parametres noyau associes | Tester le repo dans QEMU/KVM |
| Locale | `en_US.UTF-8` + `LC_TIME/PAPER/MEASUREMENT=en_GB`, `LC_MONETARY=de_LU` | Interface anglaise, formats europeens, euro |

Parametres noyau (`templates/limine.default`) :

```
nvidia_drm.modeset=1 nvidia_drm.fbdev=1 amd_pstate=active zswap.enabled=0 nowatchdog split_lock_detect=off quiet loglevel=3
```

Options des modules NVIDIA dans `system/etc/modprobe.d/nvidia.conf` (GSP, PAT, preservation
VRAM pour le suspend).

## Verifications apres redemarrage

```bash
uname -r                                  # ...-cachyos
cat /proc/cmdline                         # parametres ci-dessus + root=
nvidia-smi                                # driver open charge
cat /sys/module/nvidia_drm/parameters/modeset   # Y
systemctl status scx                      # scx_lavd actif
cat /sys/kernel/sched_ext/root/ops        # lavd
x3d-mode                                  # frequency (defaut) ; x3d-mode cache pour tester
sensors                                   # k10temp + nct6687 + nvme
zramctl                                   # zram0 16G
sudo snapper list                         # snapshots pre/post
sudo limine-update --dry-run 2>/dev/null || cat /boot/limine.conf
```

Si `x3d-mode` repond que le driver est indisponible : verifier dans le BIOS
`CPPC Dynamic Preferred Cores = Driver`.

## Taille de l'ESP et snapshots bootables

`limine-snapper-sync` copie noyau + initramfs de chaque snapshot sur l'ESP (1 GiB). Avec les
modules NVIDIA dans l'initramfs (~180 MiB par noyau), une entree coute ~370 MiB et la
synchronisation s'arrete (« will exceed the 85% limit »). D'ou `DOTS_NVIDIA_EARLY_KMS=0` par
defaut et `MAX_SNAPSHOT_ENTRIES=3`. Verifier : `df -h /boot`, `ls -lh /boot/*.img`.

## Entree Limine par defaut

Limine numerote les lignes du menu dans l'ordre du fichier : `1` = groupe `/+Arch Linux`,
`2` = son premier noyau, `3` = le deuxieme. `DOTS_LIMINE_DEFAULT_ENTRY` (defaut 2) et
`DOTS_LIMINE_TIMEOUT` sont appliques a chaque `./install.sh 10`. Verifier l'ordre avec
`sudo grep -E '^\s*/' /boot/limine.conf` : si `linux-cachyos` n'est pas le premier du groupe,
mettre 3.

## Notes

- `cachyos-repo.sh` installe aussi le pacman modifie de CachyOS (repo `cachyos`). Il reste
  compatible avec paru et l'AUR. Pour un pacman vanilla, retirer `[cachyos]` de
  `/etc/pacman.conf` en gardant les tiers `znver4` et `cachyos-extra-znver4`.
- Le noyau `linux` de secours n'a pas de module NVIDIA : il sert a la console de depannage.
  Les modules sont declares optionnels (`nvidia?`) dans le drop-in mkinitcpio pour que la
  generation de son initramfs n'echoue pas.
- `nct6687d-dkms-git` se recompile a chaque mise a jour de noyau via DKMS (headers installes).
