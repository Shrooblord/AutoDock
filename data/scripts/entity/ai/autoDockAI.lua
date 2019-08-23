--Auto-Dock (C) 2018-2019 Shrooblord
--  Handles the automatic docking procedure. Mostly stolen from how AI trader ships do it, but integrated with the Auto-Dock beacon functionality among other things.

package.path = package.path .. ";data/scripts/config/?.lua"
package.path = package.path .. ";data/scripts/lib/?.lua"

local config = include("aDockConf")
include("sMPrint")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace AutoDock
local AutoDockAI = {}

AutoDockAI.usedDock = nil
AutoDockAI.dockStage = 0
AutoDockAI.undockStage = 0
AutoDockAI.numDocks = 0

local fromScript = "entity/ai/autoDockAI"



--Some printing functions
function AutoDockAI.printUsedDock()
    if onServer() then
        local fromFunc = "printUsedDock"
        local msg = "dock: "..tostring(AutoDockAI.usedDock)

        prtDbg(tostring(msg), 0, config.modID, 3, fromScript, fromFunc, "SERVER")
    end
end

function AutoDockAI.printDockStage(ship)
    if onServer() then
        local fromFunc = "printDockStage"
        local msg = "dockStage: "..tostring(ship:getValue("dockStage"))

        prtDbg(tostring(msg), 0, config.modID, 4, fromScript, fromFunc, "SERVER")
    end
end

function AutoDockAI.printDone()
    if onServer() then
        local fromFunc = "printDone"
        local msg = "AutoDockAI: Docking complete."

        prtDbg(tostring(msg), 0, config.modID, 2, fromScript, fromFunc, "SERVER")
    end
end


--figure out where to spawn the Docking Beacon based on ship and station sizes
function AutoDockAI.findBeaconTarget(ship, station, pos, dir)
    if ship:getValue("autoDockAbort") == true then return end

    local fromFunc = "findBeaconTarget"
    local offset
    local shipBoundsRadius
    local stationBoundsRadius
    
    pos = station.position:transformCoord(pos)
    dir = station.position:transformNormal(dir)
    
    --Base the distance from the dock to the Beacon on the relative size difference between the dock and the ship
    shipBoundsRadius = ship:getBoundingSphere().radius
    stationBoundsRadius = station:getBoundingSphere().radius
    
    if stationBoundsRadius > shipBoundsRadius then
        offset = 500 * shipBoundsRadius / stationBoundsRadius
    else
        --This shouldn't happen very often, but still...
        offset = 500 * stationBoundsRadius / shipBoundsRadius
    end

    local msg = "offset calc: "..tostring(offset)
    prtDbg(msg, 0, config.modID, 4, fromScript, fromFunc, ship.name)
    
    --But never make it less than 0.25 km, 'cause that's a little too close of a shave
    if offset < 25 then
        offset = 25
    end
    
    --and never make it more than 1 km, 'cause that's overkill
    if offset > 100 then
        offset = 100
    end

    msg = "offset final: "..tostring(offset)
    prtDbg(msg, 0, config.modID, 4, fromScript, fromFunc, ship.name)

    pos = pos + dir * (shipBoundsRadius + offset)

    local up = station.position.up

    return MatrixLookUpPosition(-dir, up, pos)
end



--The bulk of this mod's functionality: perform the Auto-Docking manoeuvre
function AutoDockAI.autoDock(ship, station)
    local fromFunc = "autoDock"
    
    AutoDockAI.dockStage = ship:getValue("dockStage") or 0
    AutoDockAI.usedDock = ship:getValue("dockUsed") or AutoDockAI.usedDock

    local docks = DockingPositions(station)
    
    if AutoDockAI.dockStage == 0 then

        -- no dock chosen yet -> find one
        if not AutoDockAI.usedDock then
            -- if there are no docks on the station at all, we can't do anything
            if not docks:getDockingPositions() then
                return false
            end

            -- find a free dock
            local freeDock = docks:getFreeDock(ship)
            if freeDock then
                AutoDockAI.usedDock = freeDock
            end            
        end

        if AutoDockAI.usedDock then
            if not docks:isDockFree(AutoDockAI.usedDock, ship) then
                -- if the dock is not free, reset it and look for another one
                AutoDockAI.usedDock = nil
            end
        end

        -- still no free dock found? nothing we can do
        if not AutoDockAI.usedDock then return end
        
        -- return the position of the light line of the dock
        local pos, dir = docks:getDockingPosition(AutoDockAI.usedDock)
        --local target = pos + dir * 45
        --local target = station.position:transformCoord(pos + dir * 45)
        local target = AutoDockAI.findBeaconTarget(ship, station, pos, dir)
        
        local msg = "pos: "..tostring(pos)
        prtDbg(msg, 0, config.modID, 3, fromScript, fromFunc, ship.name)

        msg = "dir: "..tostring(dir)
        prtDbg(msg, 0, config.modID, 3, fromScript, fromFunc, ship.name)

        msg = "target: "..tostring(target)
        prtDbg(msg, 0, config.modID, 3, fromScript, fromFunc, ship.name)
        
        AutoDockAI.printUsedDock()
        
        ship:setValue("dockUsed", AutoDockAI.usedDock)
        
        if docks:inLightArea(ship, AutoDockAI.usedDock) then
            -- when the light area was reached, start stage 1 of the docking process
            ship:setValue("dockStage", 1)  --this is also set by the Beacon; it's set here as well in case the Beacon activation conditions aren't met, but the ship still ends up in the light area
            AutoDockAI.printDockStage(ship)
            AutoDockAI.printUsedDock()
            return false, false, target
        else
            return false, false, target
        end
    end
    
    -- stage 1 is flying towards the dock inside the light-line
    if AutoDockAI.dockStage == 1 then
        AutoDockAI.printUsedDock()
        -- if docking doesn't work, go back to stage 0 and find a free dock
        
        if not docks:startDocking(ship, AutoDockAI.usedDock) then
            --ship:setValue("dockStage", 0)
            AutoDockAI.printDockStage(ship)
            return false
        else
            -- docking worked
            ship:setValue("dockStage", 2)
            
            Velocity(ship.index).velocity = dvec3(0, 0, 0)
            ship.desiredVelocity = 0
        end
    end

    if AutoDockAI.dockStage == 2 then
        -- once the ship is at the dock, we're done
        if station:isDocked(ship) then
            AutoDockAI.printDone()
            return true
        else
            -- tractor beams are active
            AutoDockAI.printDockStage(ship)
            AutoDockAI.printUsedDock()
            return false, true
        end
    end

    return false
end



function AutoDockAI.disembark(ship, station)

    local docks = DockingPositions(station)

    if AutoDockAI.undockStage == 0 then
        docks:startUndocking(ship)
        AutoDockAI.undockStage = 1
    elseif AutoDockAI.undockStage == 1 then

        if not docks:isUndocking(ship) then
            AutoDockAI.undockStage = 0
            return true
        end
    end

    return false
end

function AutoDockAI.secure(data)
    data.AutoDockAI = {}
    data.AutoDockAI.usedDock = AutoDockAI.usedDock
    data.AutoDockAI.dockStage = AutoDockAI.dockStage
    data.AutoDockAI.undockStage = AutoDockAI.undockStage
end

function AutoDockAI.restore(data)
    if not data.AutoDockAI then return end

    AutoDockAI.usedDock = data.AutoDockAI.usedDock
    AutoDockAI.dockStage = data.AutoDockAI.dockStage or 0
    AutoDockAI.undockStage = data.AutoDockAI.undockStage or 0
end

return AutoDockAI