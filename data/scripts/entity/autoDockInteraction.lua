--Auto-Dock (C) 2018-2019 Shrooblord
package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/entity/?.lua"
include("stringutility")
include ("faction")
include("callable")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace AutoDockUI
AutoDockUI = {}

local player
local playerCraft
local station

