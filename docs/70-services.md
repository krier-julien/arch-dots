# 70 - nxapi : presence Switch 2 dans Discord

Script : `scripts/70-services.sh` (`./install.sh 70`). nxapi est installe par npm dans
`~/.local` (pas de paquet AUR fiable).

## Principe

Nintendo n'expose la presence que via l'app Nintendo Switch Online. nxapi se connecte avec un
**compte Nintendo secondaire** (ami du compte principal) et lit la presence de ce dernier,
puis l'envoie a Discord (Vesktop, arRPC active). Ne jamais utiliser le compte principal :
Nintendo peut invalider sa session NSO sur console.

## Configuration (une fois)

```bash
nxapi nso auth                    # se connecter avec le compte SECONDAIRE (lien a ouvrir dans Brave)
nxapi nso users                   # -> na_id du compte secondaire  => NXAPI_USER
nxapi nso friends                 # -> nsa_id du compte principal  => NXAPI_FRIEND_NSAID
cp ~/.config/nxapi/presence.env.example ~/.config/nxapi/presence.env
micro ~/.config/nxapi/presence.env
systemctl --user enable --now nxapi-presence
journalctl --user -fu nxapi-presence
```

Si tu n'as qu'un seul client Discord, supprimer `--discord-preferred-user ${NXAPI_DISCORD_USER}`
dans `~/.config/systemd/user/nxapi-presence.service` (symlink vers `dots/nxapi`).

## Notes

- Les jetons sont stockes par nxapi dans `~/.local/share/nxapi` ; `presence.env` est ignore
  par git.
- Le service demarre avec la session graphique et redemarre seul en cas d'erreur reseau.
- Alternative sans compte secondaire : la « presence API » de nxapi-auth
  (https://nxapi-auth.fancy.org.uk/), voir la doc nxapi.
- Discord doit tourner (Vesktop, workspace 2) pour que la presence apparaisse.
