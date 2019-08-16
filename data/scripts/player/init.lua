--TEMPORARY; DELETE THIS

package.path = package.path .. ";data/scripts/config/?.lua"
package.path = package.path .. ";data/scripts/lib/?.lua"

local aDockConf = include("aDockConf")
include("sMPrint")

prt("Test string to see if this works!", 0, aDockConf.id, "player/init.lua", "no", "PLYR")
prtDbg("A debug test string that only works with dbgLevel==4 :O", 0, aDockConf.id, 4, "player/init.lua", "no", "PLYR")
