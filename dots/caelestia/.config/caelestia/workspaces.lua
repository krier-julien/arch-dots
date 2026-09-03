-- Workspaces fixes + apps en autostart. Charge par hypr-user.lua.
-- Trouver la classe d'une fenetre : hyprctl clients | grep -E 'class|title'
local M = {}

-- Classes des applications (regex Hyprland). Ajuster si `hyprctl clients` montre autre chose.
M.apps = {
    -- Classes relevees avec `hyprctl clients` sur la machine cible
    browser = { class = "brave-origin",                                   ws = "1", cmd = "brave-origin" },
    discord = { class = "discord|vesktop|equibop",                        ws = "2", cmd = "vesktop" },
    steam   = { class = "steam",                                          ws = "3", cmd = "steam" },
    obs     = { class = "com.obsproject.Studio",                          ws = "4", cmd = "obs" },
    music   = { class = "com.github.th-ch.youtube-music|pear-desktop",    ws = "5", cmd = "youtube-music" },   -- binaire fourni par pear-desktop-bin
    plex    = { class = "com.edde746.plezy",                              ws = "6", cmd = "plezy" },
}
-- Jeux : voir gaming.lua (workspace 7)
M.games_ws    = "7"
M.games_class = "steam_app_[0-9]+|steam_app_default|gamescope"

function M.setup(monitor)
    -- 1..7 lies a la TV et persistants : ils existent des le demarrage, dans l'ordre,
    -- et reviennent sur la TV apres un debranchement/rebranchement (TV eteinte).
    for i = 1, 7 do
        hl.workspace_rule({ workspace = tostring(i), monitor = monitor, persistent = true, default = (i == 1) })
    end

    -- Chaque app est verrouillee sur son workspace. " silent" : la fenetre y est envoyee sans
    -- voler le focus (Steam ouvre plusieurs fenetres en decale au demarrage).
    for _, app in pairs(M.apps) do
        hl.window_rule({ match = { class = app.class }, workspace = app.ws .. " silent" })
    end
    -- Steam : ses popups Xwayland sans titre (overlay, notifications) suivent aussi
    hl.window_rule({ match = { class = "steam", title = "" }, workspace = M.apps.steam.ws .. " silent" })

    -- Les jeux prennent le workspace 7 et le focus
    hl.window_rule({ match = { class = M.games_class }, workspace = M.games_ws })

    -- Caelestia envoie Discord et les lecteurs musique sur des workspaces speciaux :
    -- on retire ces tags pour que nos workspaces fixes s'appliquent.
    hl.window_rule({ match = { class = M.apps.discord.class }, tag = "-communication_app" })
    hl.window_rule({ match = { class = M.apps.music.class },   tag = "-music_player" })

    -- Autostart (dans l'ordre des workspaces). `uwsm app` place chaque app dans sa propre
    -- unite systemd (logs, cgroup, arret propre) ; hors session uwsm il execute directement.
    hl.on("hyprland.start", function()
        local order = { "browser", "discord", "steam", "obs", "music", "plex" }
        for _, name in ipairs(order) do
            hl.exec_cmd("uwsm app -- " .. M.apps[name].cmd)
        end
    end)
end

return M
