-- Automatisation jeu : V-Cache du 7950X3D des qu'une fenetre de jeu apparait,
-- retour en mode frequence quand le dernier jeu se ferme. Complementaire a gamemode
-- (dots/gaming/.config/gamemode.ini) pour les jeux lances sans `gamemoderun`.
local M = {}
local pattern = "steam_app_[0-9]+|steam_app_default|gamescope"

local function is_game(win)
    local class = win and win.class
    if not class then return false end
    for alt in string.gmatch(pattern, "[^|]+") do
        -- Lua n'a pas d'alternance : on teste chaque motif (traduit en pattern Lua)
        local lua_pat = "^" .. alt:gsub("%[0%-9%]%+", "%%d+") .. "$"
        if string.find(class, lua_pat) then return true end
    end
    return false
end

local function games_running(except)
    for _, w in ipairs(hl.get_windows() or {}) do
        if w ~= except and is_game(w) then return true end
    end
    return false
end

function M.setup()
    hl.on("window.open", function(win)
        if is_game(win) then
            hl.exec_cmd("x3d-mode cache")
        end
    end)
    hl.on("window.close", function(win)
        if is_game(win) and not games_running(win) then
            hl.exec_cmd("x3d-mode frequency")
        end
    end)
end

return M
