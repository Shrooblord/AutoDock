local AutoDockAI = {}

AutoDockAI.usedDock = nil
AutoDockAI.dockStage = 0
AutoDockAI.printVals = 0 --set to 0 for no debug, 1 for some debug and 2 for extensive debug logging
AutoDockAI.numDocks = 0

function AutoDockAI.printUsedDock()
    if onServer() and AutoDockAI.printVals > 0 then
        print("AutoDockAI: dock: "..tostring(AutoDockAI.usedDock))
    end
end

function AutoDockAI.printDockStage()
    if onServer() and AutoDockAI.printVals > 0 then
        print("AutoDockAI: dockStage: "..tostring(ship:getValue("dockStage")))
    end
end

function AutoDockAI.printDone()
    if onServer() and AutoDockAI.printVals > 0 then
        print("AutoDockAI: Docking complete.")
    end
end

function AutoDockAI.findBeaconTarget(ship, station, pos, dir)
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
        --print(tostring(offset))
    else
        --This shouldn't happen very often, but still...
        offset = 500 * stationBoundsRadius / shipBoundsRadius
        --print(tostring(offset))
    end
    
    --But never make it less than 0.25 km, 'cause that's a little too close of a shave
    if offset < 25 then
        offset = 25
    end
    
    --and never make it more than 1 km, 'cause that's overkill
    if offset > 100 then
        offset = 100
        --print(tostring(offset))
    end

    pos = pos + dir * (shipBoundsRadius + offset)

    local up = station.position.up

    return MatrixLookUpPosition(-dir, up, pos)
end

function AutoDockAI.autoDock(ship, station)
    
    AutoDockAI.dockStage = ship:getValue("dockStage") or 0
    AutoDockAI.printVals = AutoDockAI.printVals or 0
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
        
        if AutoDockAI.printVals == 2 then
            print("pos: "..tostring(pos))
            print("dir: "..tostring(dir))
            print("target: "..tostring(target))
        end
        
        AutoDockAI.printUsedDock()
        
        ship:setValue("dockUsed", AutoDockAI.usedDock)
        
        if docks:inLightArea(ship, AutoDockAI.usedDock) then
            -- when the light area was reached, start stage 1 of the docking process
            ship:setValue("dockStage", 1)  --this is also set by the Beacon; it's set here as well in case the Beacon activation conditions aren't met, but the ship still ends up in the light area
            AutoDockAI.printDockStage()
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
            AutoDockAI.printDockStage()
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
            AutoDockAI.printDockStage()
            AutoDockAI.printUsedDock()
            return false, true
        end
    end

    return false
end

AutoDockAI.undockStage = 0

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
