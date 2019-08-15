--AutoDock mod by Shrooblord.
--  Adds Interaction with Stations: "Press F to initiate Docking Sequence", which will automatically dock the player ship to the Station.
--  © Jango Course, 2018
package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/entity/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

require("stringutility")
require("utility")
require("faction")
require("callable")
local AutoDockAI = require("mods/AutoDock/data/scripts/entity/ai/autoDockAI")
local PlanGenerator = require("plangenerator")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace AutoDock
AutoDock = {}

local player
local stationIndex
--local script
local stage
local stageReport
local waitCount
local tractorWaitCount

local usedDock

local stageReport = false
local dockAdded = false

local dockBeacon
local keepAliveCountdown

local dying = false

keepAliveCountdown = 300  --Number of seconds the docking procedure should stay alive once stage 0 is initiated. If the player fails to come to the beacon and start the tractor beam procedure, we cancel

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
    
    return 0.2
end

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

function AutoDock.die()
    dying = true
    ship = Entity()
    
    if valid(ship) then 
        ship:setValue("dockStage", nil)
        ship:setValue("dockUsed", nil)
        ship:setValue("autoDockAbort", nil)

        ship:setValue("autoDockShowButton", false)
        
        ship:setValue("autoDockInProgress", nil)
    end
    
    if valid(dockBeacon) then
        Sector():deleteEntity(dockBeacon)
    end
    
    terminate()
end

function AutoDock.onDelete()
    if not dying then
        return AutoDock.die()
    end
end

function AutoDock.printError(errStr)
   if onServer() then
        local x,y = Sector():getCoordinates()
        print("AutoDock ERROR: ("..tostring(x)..":"..tostring(y).."):"..errStr%_t)
    end 
end

function AutoDock.talkChat(talkStr)
    local station = Entity(stationIndex)
    
    player:sendChatMessage(station.translatedTitle.." "..station.name, 4, talkStr%_t)
end

function AutoDock.initialize(player_in, stationIndex_in)
    if onServer() then
        player = Player(player_in)
        stationIndex = stationIndex_in
        local ship = Entity()

        if not stationIndex then
            AutoDock.printError("STATION_IN NIL. TERMINATING.")
            return AutoDock.die()
        end
        
        ship:setValue("autoDockShowButton", true)
        ship:setValue("autoDockInProgress", true)
        
        ship:addScriptOnce("mods/AutoDock/data/scripts/entity/autoDockButton.lua")
    end
end

function AutoDock.onDockingFinished(ship)
    AutoDock.talkChat("Docking procedure finalised. Welcome!")
    return AutoDock.die()
end

function AutoDock.abortProcedure()
    ship = Entity()
    if ship:getValue("autoDockAbort") == true then
        print("AutoDocking procedure aborted by user.")
        AutoDock.talkChat("Affirmative. Docking procedure aborted.")
        return AutoDock.die()
    end
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
    beacon:addScript("mods/AutoDock/data/scripts/entity/autoDockBeaconUI", text, args)
    
    local station = Entity(stationIndex)
    local ship = Entity()
    beacon:addScript("mods/AutoDock/data/scripts/entity/autoDockBeacon", keepAliveCountdown, station, ship)  --keep the Beacon around for as long as we want the procedure to keep alive
    
    return beacon
end
callable(AutoDock, "createDockBeacon")

function AutoDock.updateServer(timeStep)
    local ship = Entity()

    local station = Entity(stationIndex)

    -- in case the station doesn't exist anymore, abort
    if not station then
        AutoDock.printError("STATION NO LONGER EXISTS. TERMINATING.")
        return AutoDock.die()
    end
    
    AutoDock.abortProcedure()    --Internally checks whether the user has requested we abort

    local pos, dir = station:getDockingPositions()

    if not pos or not dir or not valid(station) then
        -- something is not right, abort
        AutoDock.printError("INVALID DOCKING PROCEDURE. TERMINATING.")
        if onServer() then
            local x,y = Sector():getCoordinates()
            print("AutoDock ERROR: ("..tostring(x)..":"..tostring(y).."):"%_t)
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
