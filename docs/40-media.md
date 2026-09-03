# 40 - Elgato 4K X : son en direct, OBS

Script : `scripts/40-media.sh` (`./install.sh 40`).

## Son de la console en direct (sans OBS)

Deux fichiers, symlinkes depuis `dots/media/` :

| Fichier | Role |
|---------|------|
| `~/.config/wireplumber/wireplumber.conf.d/50-elgato.conf` | Renomme l'entree audio de la carte en `elgato_4kx_in`, 48 kHz, jamais suspendue, priorite basse (ne devient pas le micro par defaut) |
| `~/.config/pipewire/pipewire.conf.d/10-elgato-loopback.conf` | Module loopback `elgato_4kx_in` -> sortie par defaut, ~10 ms de latence, reconnexion automatique |

Le loopback apparait comme un sink « Elgato 4K X -> sortie » dans pwvucontrol : son volume
regle le niveau de la console, independamment du reste. Pour couper le son de la console
(par ex. pendant un stream ou OBS gere l'audio), couper ce sink.

Verifier :

```bash
pw-cli ls Node | grep -A2 elgato          # elgato_4kx_in, elgato_loopback.capture/playback
pw-top                                     # les deux noeuds du loopback doivent etre RUNNING
pactl list short sources | grep -i elgato
```

Si le nom du noeud ALSA ne commence pas par `alsa_input.usb-Elgato`, adapter le motif dans
`50-elgato.conf` (`pactl list short sources`).

## Video

```bash
ls -l /dev/video-elgato                             # -> videoN (regle udev 71-elgato-4kx)
v4l2-ctl -d /dev/video-elgato --list-formats-ext    # formats : NV12/YUYV 3840x2160@60
cameractrls -d /dev/video-elgato                    # controles UVC (HDR tone mapping, etc.)
```

## OBS Studio

Profil `Elgato4KX` cree par la phase : 3840x2160 60 fps, NV12 / Rec.709, enregistrement
HEVC NVENC CQP 18 preset p5 en MKV dans `~/Videos/Captures`, 2 pistes audio.

Scene a creer une fois (Scene > Sources) :

1. **Peripherique de capture video (V4L2)** : peripherique `/dev/video-elgato`, format
   `NV12` (ou YUYV), 3840x2160, 60 fps, plage de couleurs Partielle. Cocher *Utiliser les
   tampons* si des frames sautent. **Ne pas** cocher la capture audio de cette source.
2. **Capture d'entree audio** : peripherique `Elgato 4K X (capture)` (le noeud
   `elgato_4kx_in`). Dans le mixeur, l'envoyer sur la piste 2 pour separer console et micro.
3. **Capture d'entree audio** : micro (piste 1 et 2).
4. Optionnel : *Application Audio Capture (PipeWire)* pour capter Discord uniquement.

Le loopback permanent continue de jouer le son de la console pendant l'enregistrement :
OBS lit le noeud Elgato directement, pas la sortie de l'ordinateur, donc pas de double.

Pour capter un jeu PC en plus : source **Game Capture (obs-vkcapture)** et lancer le jeu avec
`obs-gamecapture %command%` (ou `OBS_VKCAPTURE=1`).

Encodeurs disponibles avec la 4090 : `ffmpeg_hevc_nvenc` (defaut), `ffmpeg_av1_nvenc`
(meilleure qualite/poids, lecteur AV1 requis), `ffmpeg_nvenc` (H.264, compatibilite).
