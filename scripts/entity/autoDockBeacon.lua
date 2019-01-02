package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/entity/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

require("stringutility")
require("utility")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace AutoDockBeacon
AutoDockBeacon = {}

local timer
local station
local playerShip

function AutoDockBeacon.getUpdateInterval()
    return 0.02
end

function AutoDockBeacon.interactionPossible(playerIndex, option)
    return true
end

function AutoDockBeacon.initialize(timer_in, station_in, playerShip_in)
    if onServer() then
        timer = timer_in or AutoDockBeacon.getUpdateInterval() --If no timer was supplied, we will die within one tick
        station = station_in
        playerShip = playerShip_in
    end
end

function AutoDockBeacon.initUI()
   ScriptUI():registerInteraction("Abort Auto-Docking Procedure"%_t, "onAbort") 
end

function AutoDockBeacon.printError(errStr)
   if onServer() then
        local x,y = Sector():getCoordinates()
        print("autoDockBeacon ERROR: ("..tostring(x)..":"..tostring(y).."):"..errStr%_t)
    end 
end

function AutoDockBeacon.die()
    Sector():deleteEntityJumped(Entity())
end

function AutoDockBeacon.dieOnInvalid(invalidVar)
    AutoDockBeacon.printError("ARGUMENT "..invalidVar.." IS INVALID. KILLING...")
    return AutoDockBeacon.die()
end

function AutoDockBeacon.checkExpired()
   if timer <= 0 then
        return AutoDockBeacon.die()
    else
        timer = timer - AutoDockBeacon.getUpdateInterval()
    end 
end

function AutoDockBeacon.onAbort()
    if onClient() then
        invokeServerFunction("onAbort")
        return
    end
    
    if valid(playerShip) then
        playerShip:setValue("autoDockAbort", true)
    end
    return AutoDockBeacon.die()
end
callable(AutoDockBeacon, "onAbort")

function AutoDockBeacon.checkPlayerProximity()
    if onServer() then
        if not valid(station) then
            return AutoDockBeacon.dieOnInvalid("station")
        end
        if not valid(playerShip) then
            return AutoDockBeacon.dieOnInvalid("playerShip")
        end
        
        --bounding sphere to player. if player enters, trigger docking stage to bump to next stage
        local self = Entity()
        local sphere = self:getBoundingSphere()
        sphere.radius = sphere.radius * 3.2
      
        local entities = {Sector():getEntitiesByLocation(sphere)}
        for _, ship in pairs(entities) do
            if ship.index == playerShip.index then
                playerShip:setValue("dockStage", 1)
                return AutoDockBeacon.die()
            end
        end    
    end
end

function AutoDockBeacon.updateServer(timeStep)
    if onServer() then
        AutoDockBeacon.checkExpired()
        
        AutoDockBeacon.checkPlayerProximity()
    end
end
