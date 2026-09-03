# Config fish personnelle, sourcee par ~/.config/fish/config.fish (Caelestia)
fish_add_path --global ~/.local/bin   # nxapi (npm --prefix ~/.local) et autres outils utilisateur
set -gx EDITOR micro
set -gx BROWSER brave-origin

abbr dots 'cd ~/arch-dots'
abbr dotsi '~/arch-dots/install.sh'
abbr x3d 'x3d-mode'
abbr fans 'sudo liquidctl status'
abbr reboot 'session-exit reboot'
abbr poweroff 'session-exit poweroff'
abbr logout 'session-exit logout'
