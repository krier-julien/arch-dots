-- Config Hyprland personnelle, chargee en dernier par Caelestia (~/.config/hypr/hyprland.lua).
-- Materiel : RTX 4090 (nvidia-open) + LG G3 55" 4K 120 Hz en HDMI 2.1, scale 2.0.

-- Valeurs locales generees par scripts/20-hyprland.sh depuis config.env (non versionnees)
local ok, localcfg = pcall(require, "local")
if not ok or type(localcfg) ~= "table" then localcfg = {} end
local monitor = localcfg.monitor or "HDMI-A-1"

---------------------------------------------------------------------------
-- Ecran : 3840x2160@120, scale 2.0 (bureau 1920x1080 logique), VRR plein ecran
---------------------------------------------------------------------------
hl.monitor({
    output   = monitor,
    mode     = "3840x2160@120",
    position = "0x0",
    scale    = 2,
    vrr      = 2,          -- 0 off, 1 toujours, 2 plein ecran seulement, 3 plein ecran jeu/video
    -- bitdepth = 10,      -- 10 bits : ok sur la G3 en HDMI 2.1, mais peut casser certains captures d'ecran
    -- cm = "hdr",         -- HDR permanent ; par defaut render.cm_auto_hdr bascule seul en plein ecran
})

---------------------------------------------------------------------------
-- Rendu : tearing autorise (regle `immediate` sur le tag game de Caelestia),
-- direct scanout pour les jeux, VRR en plein ecran
---------------------------------------------------------------------------
hl.config({
    general = { allow_tearing = true },
    render  = {
        direct_scanout = 2,   -- 2 = seulement pour le content type "game"
    },
    misc    = { vrr = 2 },
    cursor  = {
        no_hardware_cursors = 2,  -- desactive les curseurs HW uniquement pendant le tearing
        no_break_fs_vrr     = 2,  -- le curseur ne force pas de frame en plein ecran VRR
        min_refresh_rate    = 48, -- plage VRR de la G3 : 48-120 Hz
    },
    xwayland = {
        force_zero_scaling = true, -- Xwayland non flou : les apps X11 gerent leur propre echelle
    },
})

---------------------------------------------------------------------------
-- Environnement NVIDIA + HiDPI pour les clients lances par Hyprland
-- (uwsm reprend les memes valeurs dans ~/.config/uwsm/env pour toute la session)
---------------------------------------------------------------------------
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("NVD_BACKEND", "direct")
hl.env("GDK_SCALE", "2")          -- apps GTK sous Xwayland (force_zero_scaling)
hl.env("XCURSOR_SIZE", "24")
hl.env("STEAM_FORCE_DESKTOPUI_SCALING", "2")  -- UI Steam a l'echelle (detail en Phase 3)

---------------------------------------------------------------------------
-- Regles de fenetres complementaires
---------------------------------------------------------------------------
-- Jeux : content type "game" (active direct scanout=2 et le VRR mode jeu), en plus du tag
-- `game` de Caelestia (opaque + immediate + idle_inhibit).
hl.window_rule({ match = { class = "steam_app_[0-9]+" }, content = "game" })
hl.window_rule({ match = { class = "gamescope" },        content = "game" })
hl.window_rule({ match = { class = "steam_app_default" }, content = "game" })

-- Steam : la fenetre principale en tiled, les popups en flottant (deja gere par Caelestia)
-- Pear Desktop (YouTube Music) sur le workspace special musique
hl.window_rule({ match = { class = "pear-desktop|com.github.th_ch.youtube_music" }, tag = "+music_player" })

-- OBS : opaque, jamais de blur ni d'opacite (apercu fidele)
hl.window_rule({ match = { class = "com.obsproject.Studio" }, opaque = true })

-- Plezy : opaque (video)
hl.window_rule({ match = { class = "plezy|Plezy" }, opaque = true })

---------------------------------------------------------------------------
-- Raccourcis complementaires
---------------------------------------------------------------------------
hl.bind("SUPER + SHIFT + G", function()
    -- bascule rapide du mode V-Cache (Phase 1) avec notification
    hl.exec_cmd([[sh -c 'm=$(x3d-mode); if [ "$m" = cache ]; then x3d-mode frequency; else x3d-mode cache; fi; notify-send "7950X3D" "amd_x3d_mode: $(x3d-mode)"']])
end)
