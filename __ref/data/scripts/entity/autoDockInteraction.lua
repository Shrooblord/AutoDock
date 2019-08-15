package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/entity/?.lua"
require("stringutility")
require ("faction")
require("callable")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace AutoDockUI
AutoDockUI = {}

local player
local playerCraft
local station

function AutoDockUI.printError(errStr)
   if onServer() then
        local x,y = Sector():getCoordinates()
        print("AutoDockInteraction ERROR: ("..tostring(x)..":"..tostring(y).."):"..errStr%_t)
    end 
end

function AutoDockUI.interactionPossible(playerIndex, option)
    player = Player(playerIndex)
    station = Entity()   --Entity() points to the Station

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
        local ship = Player().craft
        if ship == nil then return end

        local station = Entity()
        if station == nil then return end

        invokeServerFunction("resolveInteraction", station.index, Player().index)

        ScriptUI():stopInteraction()

        return
    end
end

function AutoDockUI.resolveInteraction(stationIndex, playerInd)
    if not stationIndex then
        AutoDockUI.printError("AutoDockUI.onInteract - stationIndex nil. Aborting.")
        return
    end
    if not playerInd then
        AutoDockUI.printError("AutoDockUI.onInteract - playerInd nil. Aborting.")
        return
    end

    player = Player(playerInd)
    station = Entity()   --Entity() points to the Station

    playerCraft = player.craft
    if playerCraft == nil then
        AutoDockUI.printError("AutoDockUI.onInteract - could not get playerCraft: value is nil.")
        return false
    end

    local playerShip = Entity(playerCraft.index)

    if playerShip then
        --we don't service drones (because they're buggy and will glitch getting stuck near the dock sometimes - tractor beam code doesn't expect Mining Drones)
        if playerShip.type == EntityType.Drone then
            player:sendChatMessage(station.translatedTitle.." "..station.name, 4, "Request to dock denied. Sorry, we do not extend this service to drones."%_t)
            return false
        end
    end

    if station.type == EntityType.Station then
        --if CheckFactionInteraction(playerInd, -10000) then
            --Everything A-OK. We can dock!
            playerShip:addScriptOnce("mods/AutoDock/data/scripts/entity/ai/autoDock.lua", playerInd, stationIndex)
            return true
        --else
        --    player:sendChatMessage(station.translatedTitle.." "..station.name, 4, "Request to dock denied. Our records say that we're not allowed to do business with you.\nCome back when your relations to our faction are better."%_t)
        --    return false
        --end
    end
end
callable(AutoDockUI, "resolveInteraction")