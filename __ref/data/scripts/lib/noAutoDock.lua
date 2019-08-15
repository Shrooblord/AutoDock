-- Give a station this script to disable it from spawning AutoDocks when the AutoDock Migrator scans a Sector for entities to add AutoDocks to.

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace noAutoDock
local noAutoDock = {}

function noAutoDock.initialize()
    if onServer() then
        local station = Entity()
        station:setValue("noAutoDock", true)

        if station:hasScript("mods/AutoDock/data/scripts/entity/autoDockInteraction.lua") then
            station:removeScript("mods/AutoDock/data/scripts/entity/autoDockInteraction.lua")
        end
        if station:hasScript("mods/AutoDock/data/scripts/entity/ai/autoDock.lua") then
            station:removeScript("mods/AutoDock/data/scripts/entity/ai/autoDock.lua")
        end

        print("noAutoDock: Unregistered "..tostring(station.translatedTitle).." "..tostring(station.name).." from AutoDock Migrator.")
    end
end

return noAutoDock