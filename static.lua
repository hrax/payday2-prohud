
--[[
    ProHUD Configuration
]]--
_G.ProHUD = _G.ProHUD or {};

--[[
    ProHUD Utility functions
]]--

function ProHUD:peerRankName(peer)
    local rank = ExperienceManager:rank_string(peer:rank())
    if rank ~= "" then
        rank = rank .. "-"
    end
    return peer:name() .. " (" ..  rank .. (peer:level() or '?') .. ")"
end

-- debug methods
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