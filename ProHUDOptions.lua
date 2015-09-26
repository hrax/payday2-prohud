
ProHUDOptions = ProHUDOptions or class()


-- ProHUD HUD options

ProHUDOptions.PLAYER_SCALE = 0.70
ProHUDOptions.PLAYER_GAP = 10 -- horizontal
ProHUDOptions.PLAYER_ROW = 60

ProHUDOptions.TEAMMATE_SCALE = 0.6
ProHUDOptions.TEAMMATE_GAP = 10 -- horizontal
ProHUDOptions.TEAMMATE_ROW = 45

ProHUDOptions.LABEL_HEIGHT = 20
ProHUDOptions.LABEL_GAP = 5 -- vertical

ProHUDOptions.PANEL_GAP = 5 -- horizontal

--[[
    ProHUD Configuration
]]--
ProHUD = ProHUD or class()

--[[
    ProHUD Utility functions
]]--
function ProHUD:inGame()
    return CopDamage ~= nil
end

function ProHUD:peerRankName(peer)
    local rank = ExperienceManager:rank_string(peer:rank())
    if rank ~= "" then
        rank = rank .. "-"
    end
    return peer:name() .. " (" ..  rank .. (peer:level() or '?') .. ")"
end

function ProHUD:debugPanel(panel, color)
    panel:rect({      --TEMPORARY
        blend_mode = "normal",
        color = color or Color.white,
        alpha = 0.10,
        h = panel:h(),
        w = panel:w(),
        layer = -10,
    })
end