-- Overrides des variables Caelestia (reference : ~/.config/hypr/variables.lua).
-- Ce fichier n'est jamais touche par `caelestia update`.
return {
    -- Apps
    terminal     = "foot",
    browser      = "brave-origin",     -- verifier le nom du binaire : ls /usr/bin | grep -i brave
    editor       = "foot micro",
    fileExplorer = "thunar",
    audioSettings = "pwvucontrol",

    -- Curseur (Bibata, taille logique ; Hyprland la multiplie par le scale 2.0)
    cursorTheme  = "Bibata-Modern-Classic",
    cursorSize   = 24,

    -- Sur une TV 55", un peu plus d'air entre les fenetres
    windowGapsIn        = 6,
    windowGapsOut       = 12,
    singleWindowGapsOut = 24,
    windowRounding      = 16,

    -- Pas de mise en veille par geste : machine fixe
    sleepGestureCmd = "loginctl lock-session",
}
