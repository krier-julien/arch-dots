# 70 - nxapi : presence Switch 2 dans Discord

Script : `scripts/70-services.sh` (`./install.sh 70`). nxapi est installe par npm dans
`~/.local`, version epinglee par `NXAPI_VERSION` dans `config.env` (`1.6.1-next.254` : la
presence Switch 2 demande une pre-release).

## Principe

Nintendo n'expose la presence que via l'app Nintendo Switch Online. nxapi se connecte avec un
**compte Nintendo secondaire** (ami du compte principal) et lit la presence de ce dernier,
puis l'envoie a Discord (Vesktop, arRPC active). Ne jamais utiliser le compte principal :
Nintendo peut invalider sa session NSO sur console.

## Configuration (une fois)

```bash
nxapi nso auth                    # se connecter avec le compte SECONDAIRE (lien a ouvrir dans Brave)
nxapi nso friends                 # -> NSA ID du compte principal => NXAPI_FRIEND_NSAID (6a3756fd9acdec95)
cp ~/.config/nxapi/presence.env.example ~/.config/nxapi/presence.env
micro ~/.config/nxapi/presence.env  # ajuster NXAPI_EXTRA_ARGS si besoin (--user, --discord-user)
systemctl --user enable --now nxapi-presence
journalctl --user -fu nxapi-presence
```

Test manuel equivalent au service :

```bash
nxapi nso presence --friend-nsaid 6a3756fd9acdec95 --discord-preconnect --show-play-time approximate
```

## Migration depuis un service existant

Si un `nxapi.service` maison existe deja dans `~/.config/systemd/user/`, le desactiver avant
d'activer `nxapi-presence` (les deux se connecteraient a Discord) :

```bash
systemctl --user disable --now nxapi.service
```

## Notes

- Les jetons sont stockes par nxapi dans `~/.local/share/nxapi` ; `presence.env` est ignore
  par git.
- Le service demarre avec la session graphique et redemarre seul en cas d'erreur reseau.
- Alternative sans compte secondaire : la « presence API » de nxapi-auth
  (https://nxapi-auth.fancy.org.uk/), voir la doc nxapi.
- Discord doit tourner (Vesktop, workspace 2) pour que la presence apparaisse.
