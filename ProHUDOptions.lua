
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

function ProHUD:romanRank(rank)
    if not rank then
        return "?"
    end

    if rank <= 0 then
        return "0"
    end

    local numbers = { 1, 5, 10, 50, 100, 500, 1000  }
    local chars = { "I", "V", "X", "L", "C", "D", "M" }
    local roman = ""
    for i = #numbers, 1, -1 do
        local num = numbers[i]
        while rank - num >= 0 and rank > 0 do
            roman = roman .. chars[i]
            rank = rank - num
        end
        for j = 1, i - 1 do
            local num2 = numbers[j]
            if rank - (num - num2) >= 0 and num > rank and rank > 0 and num - num2 ~= num2 then
                roman = roman .. chars[j] .. chars[i]
                rank = rank - (num - num2)
                break
            end
        end
    end
    return roman
end

function ProHUD:peerRankName(peer)
    local rank = ProHUD:romanRank(peer:rank())
    return peer:name() .. " (" .. ProHUD:romanRank(peer:rank()) .. "-" .. (peer:level() or '?') .. ")"
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