-- Give a station this script to disable it from spawning AutoDocks when the AutoDock Migrator scans a Sector for entities to add AutoDocks to.

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace noAutoDock
local noAutoDock = {}

function noAutoDock.initialize()
    if onServer() then
        local station = Entity()
        station:setValue("noAutoDock", true)
        print("noAutoDock: Unregistered Station from AutoDock Migrator.")
    end
end

return noAutoDock