# 80 - Checklist de validation

A derouler apres `./install.sh` complet et un redemarrage.

## Systeme (phase 1)
- [ ] `uname -r` contient `cachyos` ; `cat /proc/cmdline` contient `nvidia_drm.modeset=1`
- [ ] `nvidia-smi` fonctionne ; `cat /sys/module/nvidia_drm/parameters/modeset` = `Y`
- [ ] `systemctl status scx` actif, `cat /sys/kernel/sched_ext/root/ops` = `lavd`
- [ ] `x3d-mode` repond (`frequency` au repos)
- [ ] `sensors` montre k10temp et nct6687 ; `zramctl` montre zram0 16G
- [ ] `sudo snapper list` montre des snapshots pre/post ; le menu Limine a une entree Snapshots

## Bureau (phase 2)
- [ ] SDDM affiche le theme choisi ; session Hyprland (uwsm-managed) demarre
- [ ] `hyprctl monitors` : 3840x2160@120, scale 2.00
- [ ] Les 7 workspaces existent ; Brave en 1, Discord 2, Steam 3, OBS 4, Pear 5, Plezy 6
- [ ] Verrouillage apres 15 min ; l'ecran ne s'eteint jamais seul
- [ ] Eteindre/rallumer la TV pendant le verrouillage : la session revient intacte
- [ ] Shell Caelestia : lanceur (Super), palette (`caelestia wallpaper -f ...`)

## Jeu (phase 3)
- [ ] `/dev/ntsync` present ; MangoHUD ligne `winesync` = ntsync en jeu
- [ ] En jeu plein ecran : `hyprctl monitors` -> `vrr: true`, `directScanoutTo` != 0
- [ ] `x3d-mode` = `cache` pendant le jeu, `frequency` apres
- [ ] MangoHUD plafonne a 117 FPS ; UI Steam et overlay lisibles a 3 m
- [ ] ProtonPlus liste GE-Proton / Proton-CachyOS

## Capture (phase 4)
- [ ] `/dev/video-elgato` existe ; `pw-cli ls Node | grep elgato` montre `elgato_4kx_in`
- [ ] Le son de la console sort sur les enceintes sans OBS ; sink « Elgato 4K X -> sortie » dans pwvucontrol
- [ ] OBS : source V4L2 4K60 fluide, encodage HEVC NVENC sans frames perdues

## Materiel (phase 5)
- [ ] `sudo liquidctl status` : pompe, liquide, 4 canaux ; `systemctl status liquidctl-apply` ok
- [ ] Apres une veille/reprise, les vitesses sont reappliquees

## Apps et services (phases 6-7)
- [ ] `xdg-settings get default-web-browser` = `brave-origin.desktop`
- [ ] Vesktop : partage d'ecran fonctionne, arRPC actif
- [ ] `systemctl --user status nxapi-presence` actif ; presence visible dans Discord
