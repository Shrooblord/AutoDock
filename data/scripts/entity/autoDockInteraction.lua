--Auto-Dock (C) 2018-2019 Shrooblord
package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/entity/?.lua"
package.path = package.path .. ";data/scripts/config/?.lua"

include("faction")
include("callable")
include("sMPrint")
local config = include("aDockConf")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace AutoDockUI
AutoDockUI = {}

local player
local playerCraft
local station

local fromScript = "entity/autoDockInteraction"

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

--error-checks the current situation, then adds the autoDock.lua script to the player ship, initiating the mod's core behaviour; Auto-Docking sequence activate!
function AutoDockUI.resolveInteraction(stationIndex, playerInd)
    local fromFunc = "resolveInteraction"

    if not stationIndex then
        local err = "stationIndex nil. Aborting."
        prt(err, 1, config.modID, fromScript, fromFunc)
        return
    end
    if not playerInd then
        local err = "playerInd nil. Aborting."
        prt(err, 1, config.modID, fromScript, fromFunc)
        return
    end

    player = Player(playerInd)
    station = Entity()   --Entity() points to the Station

    playerCraft = player.craft
    if playerCraft == nil then
        local err = "could not get playerCraft: value is nil."
        prt(err, 1, config.modID, fromScript, fromFunc)
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

    if station.isStation then
        --if CheckFactionInteraction(playerInd, -10000) then
            --Everything A-OK. We can dock!
            playerShip:addScriptOnce("ai/autoDock.lua", playerInd, stationIndex)
            return true
        --else
        --    player:sendChatMessage(station.translatedTitle.." "..station.name, 4, "Request to dock denied. Our records say that we're not allowed to do business with you.\nCome back when your relations to our faction are better."%_t)
        --    return false
        --end
    end
end
callable(AutoDockUI, "resolveInteraction")


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
