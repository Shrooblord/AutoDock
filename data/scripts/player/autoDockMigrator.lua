--AutoDock migration script.
--  Adds the new AutoDock functionality to older Stations.

function initialize()
    if onServer() then
        print("AutoDock Migrator registered!")
    end
end
    
function onSectorChanged()
    if onServer() then
        local stations = {Sector():getEntitiesByType(EntityType.Station)}
        local stationsTouched = 0
        local touched = false
        
        for i, station in pairs(stations) do
            local autoDockInstalled = station:getValue("autoDockScriptEnabled")
            if not autoDockInstalled then
                local unsubscribeAutoDock = station:getValue("noAutoDock")
                if unsubscribeAutoDock then
                    print("AutoDock Migrator: Skipping "..tostring(station.translatedTitle).." "..tostring(station.name).."; it has indicated that it does not wish to receive any AutoDocks.");
                else
                    print("AutoDock Migrator: Adding AutoDocks to "..tostring(station.translatedTitle).." "..tostring(station.name)..".")
                    station:addScriptOnce("mods/AutoDock/data/scripts/entity/autoDockInteraction.lua")
                    station:setValue("autoDockScriptEnabled", true)
                    stationsTouched = stationsTouched + 1

                    if not touched then
                        touched = true
                    end
                end
            end
        end
        
        if touched then
            print("***================================***")
            if stationsTouched == 1 then
                print("AutoDock Migrator: Added AutoDocks to 1 Station in this Sector.\n")
            else
                print("AutoDock Migrator: Added AutoDocks to "..tostring(stationsTouched).." Stations in this Sector.\n")
            end
        end
    end
end
