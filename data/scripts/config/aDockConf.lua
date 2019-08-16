--Auto-Dock (C) 2018-2019 Shrooblord
--Configuration file for the Auto-Dock mod.

package.path = package.path .. ";data/scripts/config/?.lua"

include("sMConf")

local aDockConf = {
    id = "AD",          --identifier for the mod used in print strings, in this case, "Auto-Dock"
    develop = false,    --development/debug mode
    dbgLevel = 4,       --0 = off; 1 = info; 2 = verbose; 3 = extremely verbose; 4 = I WANT TO KNOW EVERYTHING
}

table.insert(sMConf, aDockConf)

return aDockConf
