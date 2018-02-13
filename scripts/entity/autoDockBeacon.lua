package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/entity/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

require("stringutility")
require("utility")

local timer
local station
local playerShip
local AutoDockAI

function getUpdateInterval()
    return 0.02
end

function interactionPossible(playerIndex, option)
    return true
end

function initialize(timer_in, station_in, playerShip_in)
    if onServer() then
        timer = timer_in or getUpdateInterval() --If no timer was supplied, we will die within one tick
        station = station_in
        playerShip = playerShip_in
    end
end

function initUI()
   ScriptUI():registerInteraction("Abort Auto-Docking Procedure"%_t, "onAbort") 
end

function printError(errStr)
   if onServer() then
        local x,y = Sector():getCoordinates()
        print("autoDockBeacon ERROR: ("..tostring(x)..":"..tostring(y).."):"..errStr%_t)
    end 
end

function die()
    Sector():deleteEntityJumped(Entity())
end

function dieOnInvalid(invalidVar)
    printError("ARGUMENT "..invalidVar.." IS INVALID. KILLING...")
    return die()
end

function checkExpired()
   if timer <= 0 then
        return die()
    else
        timer = timer - getUpdateInterval()
    end 
end

function onAbort()
    if onClient() then
        invokeServerFunction("onAbort")
        return
    end
    
    if valid(playerShip) then
        playerShip:setValue("autoDockAbort", true)
    end
    return die()
end

function checkPlayerProximity()
    if onServer() then
        if not valid(station) then
            return dieOnInvalid("station")
        end
        if not valid(playerShip) then
            return dieOnInvalid("playerShip")
        end
        
        --bounding sphere to player. if player enters, trigger docking stage to bump to next stage
        local self = Entity()
        local sphere = self:getBoundingSphere()
        sphere.radius = sphere.radius * 3.2
      
        local entities = {Sector():getEntitiesByLocation(sphere)}
        for _, ship in pairs(entities) do
            if ship.index == playerShip.index then
                playerShip:setValue("dockStage", 1)
                return die()
            end
        end    
    end
end

function updateServer(timeStep)
    if onServer() then
        checkExpired()
        
        checkPlayerProximity()
    end
end
