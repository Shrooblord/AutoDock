--Auto-Dock (C) 2018-2019 Shrooblord
--  Adds Interaction with Stations: "Press F to initiate Docking Sequence", which will automatically dock the player ship to the Station after they fly into the Docking Beacon.

package.path = package.path .. ";data/scripts/?.lua"
package.path = package.path .. ";data/scripts/config/?.lua"
package.path = package.path .. ";data/scripts/entity/?.lua"
package.path = package.path .. ";data/scripts/entity/ai/?.lua"
package.path = package.path .. ";data/scripts/lib/?.lua"

local config = include("aDockConf")
include("sMPrint")
include("stringutility")
include("utility")
include("faction")
include("callable")
local AutoDockAI = include("autoDockAI")
local PlanGenerator = include("plangenerator")
local Placer = include("placer")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace AutoDock
AutoDock = {}

local fromScript = "entity/ai/autoDock"

local player
local stationIndex

local stage
local stageReport = false
local dockAdded = false
local usedDock
local waitCount
local tractorWaitCount

local dockBeacon
local keepAliveCountdown = config.keepAliveCountdown

local dying = false



function AutoDock.getStationIndex()
    return stationIndex
end

function AutoDock.getUpdateInterval()  -- how many seconds between executions of this script; basically inverse tickrate
    if AutoDockAI then
        if AutoDockAI.dockStage then            --Variable update cycles based on what point of the script we're in; some parts of the process require more accurate checking, while others don't
            if AutoDockAI.dockStage == 0 then
                return 0.2
            elseif AutoDockAI.dockStage == 1 then
                return 0.02
            elseif AutoDockAI.dockStage == 2 then
                return 0.2
            end
        end
    end
    
    return 1
end



--script termination & deletion
function AutoDock.die()
    if onServer() then
        dying = true
        local ship = Entity()
        
        if valid(ship) then
            ship:setValue("dockStage", nil)
            ship:setValue("dockUsed", nil)
            ship:setValue("autoDockAbort", nil)

            ship:setValue("autoDockShowButton", nil)
            
            ship:setValue("autoDockInProgress", nil)

            ship:removeScript("ai/autoDockAI.lua")
            ship:removeScript("autoDockButton.lua")
        end

        if valid(dockBeacon) then
            Sector():deleteEntity(dockBeacon)
        end
    end
    
    terminate()
end

function AutoDock.onDelete()
    if not dying then
        return AutoDock.die()
    end
end


--send chat messages to player
function AutoDock.talkChat(talkStr)
    local station = Entity(stationIndex)
    
    player:sendChatMessage(station.translatedTitle.." "..station.name, 4, talkStr%_t)
end


--initialise the script!
--player_in         : given when adding this script through UI interaction
--stationIndex_in   : ditto
function AutoDock.initialize(player_in, stationIndex_in)
    local fromFunc = "initialize"

    if onServer() then
        player = Player(player_in)
        stationIndex = stationIndex_in
        local ship = Entity()

        if not stationIndex then
            local err = "STATION_IN NIL. TERMINATING."
            prt(err, 1, config.modID, fromScript, fromFunc, "SERVER")
            return AutoDock.die()
        end
        
        ship:setValue("autoDockShowButton", true)
        ship:setValue("autoDockInProgress", true)
        
        ship:addScriptOnce("autoDockButton.lua")
    end
end


--end-of-docking scenarios: success, abort, failure
function AutoDock.onDockingFinished(ship)
    AutoDock.talkChat("Docking procedure finalised. Welcome!")
    return AutoDock.die()
end

function AutoDock.abortProcedure()
    local fromFunc = "abortProcedure"
    local ship = Entity()

    if ship:getValue("autoDockAbort") == true then
        prt("AutoDocking procedure aborted by user.", 0, config.modID, fromScript, fromFunc)
        AutoDock.talkChat("Affirmative. Docking procedure aborted.")
        return true
    end
    return false
end

function AutoDock.cancelProcedure()
    local ship = Entity()
    AutoDock.talkChat(ship.name..", you did not comply to protocol.\nThe docking procedure has been aborted.")
    return AutoDock.die()
end

--Every tick while we are at docking stage 0, we countdown a keepAlive timer, after which the whole docking interaction is cancelled.
--  The beacon has been destroyed, or the player left, or something else has happened. Whatever happened, we abort.
function AutoDock.keepAliveCheck()
    keepAliveCountdown = keepAliveCountdown - AutoDock.getUpdateInterval()
        
    if keepAliveCountdown <= 0 then
        AutoDock.cancelProcedure()
    end
end





--Hijhacked from SectorGenerator, with some added functionality specific to the Auto-Docker
function AutoDock.createDockBeacon(position, faction, text, args)
    if onClient() then
        invokeServerFunction("createDockBeacon", position, faction, text, args)
        return
    end
    
    local desc = EntityDescriptor()
    desc:addComponents(
       ComponentType.Plan,
       ComponentType.BspTree,
       ComponentType.Intersection,
       ComponentType.Asleep,
       ComponentType.DamageContributors,
       ComponentType.BoundingSphere,
       ComponentType.BoundingBox,
       ComponentType.Velocity,
       ComponentType.Physics,
       ComponentType.Scripts,
       ComponentType.ScriptCallback,
       ComponentType.Title,
       ComponentType.Owner,
       ComponentType.InteractionText,
       ComponentType.FactionNotifier
       )

    local plan = PlanGenerator.makeBeaconPlan()

    desc.position = position --or self:getPositionInSector()
    desc:setMovePlan(plan)
    desc.title = "Docking Beacon"%_t
    if faction then desc.factionIndex = faction.index end

    local beacon = Sector():createEntity(desc)
    beacon:addScript("autoDockBeaconUI.lua", text, args)
    
    local station = Entity(stationIndex)
    local ship = Entity()
    beacon:addScript("autoDockBeacon.lua", keepAliveCountdown, station, ship)  --keep the Beacon around for as long as we want the procedure to keep alive
    
    Placer.resolveIntersections()

    return beacon
end
callable(AutoDock, "createDockBeacon")



function AutoDock.updateServer(timeStep)
    local fromFunc = "updateServer"
    local ship = Entity()
    local station = Entity(stationIndex)

    -- in case the station doesn't exist anymore, abort
    if not station then
        local err = "STATION NO LONGER EXISTS. TERMINATING."
        prt(err, 1, config.modID, fromFunc, fromScript, "SERVER")
        return AutoDock.die()
    end
    
    if AutoDock.abortProcedure() then    --Internally checks whether the user has requested we abort
        return AutoDock.die()
    end

    local pos, dir = station:getDockingPositions()

    if not pos or not dir or not valid(station) then
        -- something is not right, abort
        local err = "INVALID DOCKING PROCEDURE. TERMINATING."
        prt(err, 1, config.modID, fromFunc, fromScript, "SERVER")

        if onServer() then
            return AutoDock.die()
        end
    else
        if not stageReport then
            AutoDock.talkChat("Request to dock acknowledged. Please proceed to the indicated\nlocation within "..tostring(keepAliveCountdown).." seconds to initiate docking procedure.")
            ship:setValue("dockStage", 0)
            stageReport = true
        end

        local docked, tractorActive, target = AutoDockAI.autoDock(ship, station)
        
        if not tractorActive then
            AutoDock.keepAliveCheck()
            
            if target then
                if not dockAdded then

                    --local faction = Faction(station.factionIndex)
                    local faction = Faction(ship.factionIndex)
                    local beaconText = ship.name..", please proceed to this location to initiate the docking procedure with "..station.translatedTitle.." "..station.name.."."

                    dockBeacon = AutoDock.createDockBeacon(target, faction, beaconText)

                    dockAdded = true
                end
            end
        end
        if docked then
            AutoDock.onDockingFinished(ship)
        end
    end
end



--loading and saving from disk
function AutoDock.restore(values)
    stationIndex = Uuid(values.stationIndex)
    --script = values.script
    stage = values.stage
    waitCount = values.waitCount

    AutoDockAI.restore(values)
end

function AutoDock.secure()
    local values =
    {
        stationIndex = stationIndex.string,
        --script = script,
        stage = stage,
        waitCount = waitCount,
    }

    AutoDockAI.secure(values)

    return values
end
