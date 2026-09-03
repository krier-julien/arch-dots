# 50 - Kraken Elite et Lian Li Uni SL V2 : vitesses fixes avec liquidctl

Script : `scripts/50-hardware.sh` (`./install.sh 50`). liquidctl >= 1.16.0 requis (driver
`lianli_uni`, hub Uni SL/SL v2/AL/SL-Infinity ; Kraken 2023 Elite depuis 1.14.0).

## Fonctionnement

- `/etc/liquidctl/speeds.conf` : les valeurs (pompe, 4 canaux du hub, ecran LCD).
- `/usr/local/bin/liquidctl-apply` : `liquidctl initialize all` puis applique le fichier.
- `liquidctl-apply.service` au boot, `liquidctl-resume.service` apres une reprise de veille
  (les vitesses fixes du hub ne survivent pas toujours a une coupure USB).

Le hub Uni n'accepte que des vitesses fixes par canal (pas de courbe embarquee), ce qui
correspond au choix retenu : le boitier est tres ventile, les vitesses sont constantes.

## Trouver le cablage des canaux

```bash
sudo liquidctl list
sudo liquidctl --match "Lian Li" set fan1 speed 100   # regarder quel groupe accelere
sudo liquidctl --match "Lian Li" set fan1 speed 45
sudo liquidctl status
```

Puis reporter dans `speeds.conf` (fan1..fan4) et `sudo systemctl restart liquidctl-apply`.
Valeurs de depart : intake 45 %, radiateur 55 %, arriere 50 %, pompe 70 %.

## Kraken Elite : ecran

```bash
sudo liquidctl --match kraken set lcd screen liquid          # temperature du liquide
sudo liquidctl --match kraken set lcd screen gif ~/anim.gif  # 640x640
sudo liquidctl --match kraken set lcd brightness 60
```

`KRAKEN_LCD=` dans `speeds.conf` accepte `liquid`, `duty` ou un chemin de gif.
L'anneau RGB du Kraken Elite n'est pas encore pilotable par liquidctl.

## Surveillance

```bash
sudo liquidctl status          # temperature liquide, RPM pompe, RPM des 4 canaux
sensors                        # k10temp (CPU), nct6687 (carte mere), nvme
nvtop / nvidia-smi             # GPU
```

Regle de securite : si la temperature du liquide depasse 45 °C en jeu, monter
`LIANLI_FAN3` (radiateur) et `KRAKEN_PUMP`.
