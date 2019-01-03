Version:
1.1

SHROOBLORD:

[[TO-DOS]]
1. Add Alliance support

2. Change Interaction text with Station once Auto-Dock procedure is intialised.

3. Add a new script that makes use of autoDockAI's disembark() function. Its Interaction option with a Station is only available when docked to that Station.

4. Add Tutorial box to illustrate how to use these new beacons.

5. Add some more random dialog. Look at how Stations randomise their welcome text. Do that.

6. Add Hotkey to Auto-Dock. Bringing up F Interaction Menu every time is lame. Look at the Systems Overhaul mod thingy you downloaded (the one with custom UI and alt-codes) for how to do so.

7. Make Beacon invulnerable to damage. Currently it can be destroyed (which is bad).

====

[[TESTING]]
1. Many, many Stations and different Docks

2. Big ships, small ships

3. Different speeds of approach

4. All angles of approach work as intended

5. UI shows/hides under correct circumstances:
    - Button shows when Auto-Docking Procedure started
    - "Auto-Dock to Station" Interaction shows when A) not Docked at Station and B) Auto-Docking Procedure has not been started
    - "Disembark" Interaction shows when Docked at Station
    - No options / UI appear when the player is piloting a Station
    
6. All Stations and Factories get functionality added in; Migrator works

====

[[INSTALLATION]]

0. Download ShipScriptLoader

1. Unzip /mods/ into /Avorion/

2. add

    Config.Add("mods/AutoDock/scripts/player/autoDockMigrator.lua")

to SSL config

3. add

    station:addScriptOnce("mods/AutoDock/scripts/entity/autoDockInteraction.lua")

to scripts/lib/defaultscripts.lua inside the Stations block of scripts

====

[[USAGE]]

1. This modpack comes with a Migrator Script. That is to say, the mod automatically updates old instances of Stations that were already generated in your galaxy to use the new functionality introduced by this mod. Newly generated Stations, of course, come with this same functionality out of the box.

2. Interact with a Station and choose "Auto-Dock with Station". You will be guided through what to do next; but just in case it's not clear: steer towards the Beacon that is thusly spawned.

3. Once you reach the Beacon, you will automatically be pulled in to the Dock.

4. While docked, you can Interact with the Station and choose "Disembark", which will cause the Station to push you away from its dock.

5. To abort an Auto-Docking Procedure, simply use the new UI button or Interact with the Beacon and choose "Abort Auto-Docking Procedure". You cannot abort an Auto-Docking Procedure once the Station's tractor beams are engaged.

6. You can only have one Auto-Docking Procedure active at a time. To Auto-Dock with another Station, first Abort your current Auto-Docking Procedure, or complete it. Afterwards, you'll be able to attempt a new Auto-Docking Procedure with a (different) Station.

7. Have fun! You should be able to whizz by quite quickly now and still get caught by the tractor beams, which means docking has become a whole lot easier! However, testing shows that doing anything too crazy (looking at you Velocity Security Control Bypass System Module Upgrade) may still result in you crashing head-first into the Station, so try to keep your acrobatic escapades within the realm of reason.

====

[[KNOWN ISSUES]]

1. Tiny ships like your Mining Drone may not work as intended; the tractor beams can get stuck at the end of the docking procedure. This is why the Drone is disabled when attempting to activate a Station's AutoDock while piloting it.

===

[[FOR MODDERS]]

If you want to disable AutoDocks for a Station of yours, add the following code near the top of one of its scripts:

  local noAutoDock = require ("mods/AutoDock/data/scripts/lib/noAutoDock")

This local variable is never used, but simply including it will execute the code inside the script, causing your station to be given a "noAutoDock = true" Entity Value which the AutoDock Migrator now checks for.
If this value is found, and its value is true, the AutoDock Migrator will skip that station and not add any AutoDocks to it.

If AutoDock is not installed, this value is nil, but because you're not using the value anywhere in your script, that doesn't matter. So it works with AutoDock installed, and with AutoDock not installed.

===

[[CHANGELOG]]

1.1 -- 0.20.2 Security update
    - Added Namespacing to all scripts where applicable.
    - Added "callable" functionality to remote calls.

1.0 -- Initial release