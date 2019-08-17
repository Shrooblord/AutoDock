--Auto-Dock (C) 2018-2019 Shrooblord
package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/entity/?.lua"
include ("faction")
include("callable")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace AutoDockUI
AutoDockUI = {}

local player
local playerCraft
local station

local fromScript = "autoDockInteraction"

function AutoDockUI.interactionPossible(playerIndex, option)
    player = Player(playerIndex)
    station = Entity()   --Entity() points to the Station this script is running on

    playerCraft = player.craft
    if playerCraft == nil then return false end

    local playerShip = Entity(playerCraft.index)

    if playerShip then
        --player is already engaged in an Auto-Docking Sequence
        if playerShip:getValue("autoDockInProgress") == true then
            return false
        end
        --player is already docked to this Station; no need to initiate Auto-Docking Sequence
        if station:isDocked(playerShip) then
            return false
        end
    end
    return true
end

-- create all required UI elements for the client side
function AutoDockUI.initUI()
    ScriptUI():registerInteraction("Auto-Dock to Station"%_t, "onInteract")
end

function AutoDockUI.onInteract()
    if onClient() then
        if playerCraft == nil then return end
        if station == nil then return end

        invokeServerFunction("resolveInteraction", station.index, player.index)

        ScriptUI():stopInteraction()
    end
end

