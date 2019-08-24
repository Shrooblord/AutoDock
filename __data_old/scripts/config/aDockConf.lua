--Auto-Dock (C) 2018-2019 Shrooblord
--Configuration file for the Auto-Dock mod.

package.path = package.path .. ";data/scripts/config/?.lua"

include("sMConf")

local aDockConf = {
    modID = "AD",          --identifier for the mod used in print strings, in this case, "Auto-Dock"
    develop = false,    --development/debug mode
    dbgLevel = 4,       --0 = off; 1 = info; 2 = verbose; 3 = extremely verbose; 4 = I WANT TO KNOW EVERYTHING
    keepAliveCountdown = 300,  --Number of seconds the docking procedure should stay alive once stage 0 is initiated. If the player fails to come to the beacon and start the tractor beam procedure, we cancel
}

table.insert(sMConf, aDockConf)

return aDockConf
