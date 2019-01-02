--Copy-pasta of Avorion's beacon.lua, but with a twist to display differently on-screen, namely in the Player's colour, and with an arrow pointing towards it; and no ability to change its text.
package.path = package.path .. ";data/scripts/lib/?.lua"

require ("stringutility")
require ("callable")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace AutoDockBeacon
AutoDockBeacon = AutoDockBeacon or {}

local window
local text = ""
local args = {}

function AutoDockBeacon.initialize(text_in, args_in)
    if onServer() then
        text = text_in or ""
        args = args_in or {}
    else
        Player():registerCallback("onPreRenderHud", "onRenderHud")

        AutoDockBeacon.sync()
    end
end

function AutoDockBeacon.interactionPossible(player, option)
    if option == 0 then
        if Player().index == Entity().factionIndex then return 1 end
        return false
    end
    return true
end

function AutoDockBeacon.initUI()

    local res = getResolution()
    local size = vec2(300, 250)

    local menu = ScriptUI()

    menu:registerInteraction("Close"%_t, "")
end


function AutoDockBeacon.onRenderHud()
    -- display nearest x
    if os.time() % 2 == 0 then
        local renderer = UIRenderer()
        --Only display a nice HUD overlay if it's YOUR beacon.
        if Player().index == Entity().factionIndex or Player().allianceIndex == Entity().factionIndex then
            renderer:renderEntityTargeter(Entity(), ColorRGB(0.5, 0.95, 0));
            renderer:renderEntityArrow(Entity(), 30, 10, 250, ColorRGB(0.5, 0.95, 0), 0);
        end
        renderer:display()
    end
end

function AutoDockBeacon.getText()
    return text
end

function AutoDockBeacon.sync(text_in, args_in)
    if onClient() then
        if text_in then
            InteractionText(Entity().index).text = text_in%_t % (args_in or {})
        else
            invokeServerFunction("sync")
        end
    else
        invokeClientFunction(Player(callingPlayer), "sync", text, args)
    end

end
callable(AutoDockBeacon, "sync")

function AutoDockBeacon.secure()
    return {text = text, args = args}
end

function AutoDockBeacon.restore(values)
    text = values.text or ""
    args = values.args or {}
end


