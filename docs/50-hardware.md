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

## Cablage releve

| Peripherique | Canal | Ventilateurs | Valeur |
|--------------|-------|--------------|--------|
| Lian Li Uni SL V2 | fan1 | 3x SL140 facade, intake | 45 % |
| Lian Li Uni SL V2 | fan2 | libre (0 rpm) | ignore |
| Lian Li Uni SL V2 | fan3 | 3x SL120 bas sous le GPU, intake | 45 % |
| Lian Li Uni SL V2 | fan4 | 1x SL140 arriere, exhaust | 50 % |
| Kraken 2023 Elite | fan  | 3x SL120 radiateur, exhaust (header du Kraken) | 55 % |
| Kraken 2023 Elite | pump | pompe | 70 % |

liquidctl affiche le Kraken comme « NZXT Kraken 2023 Elite (broken) » : c'est le libelle
upstream du modele 0x300C (anciennement « experimental »). Lecture, pompe et canal `fan`
fonctionnent ; l'ecran LCD est applique en best-effort (`KRAKEN_LCD=` pour ne pas y toucher).

Pour re-tester un canal : `sudo liquidctl --match "Lian Li" set fan1 speed 100`, puis
`sudo systemctl restart liquidctl-apply` pour revenir aux valeurs du fichier.

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

Regle de securite : si la temperature du liquide depasse 45 °C en jeu, monter `KRAKEN_FAN`
(radiateur) puis `KRAKEN_PUMP`. Releve au repos : liquide 39.9 °C avec pompe 35 % et
ventilateurs radiateur 35 % (reglages NZXT CAM d'origine).
