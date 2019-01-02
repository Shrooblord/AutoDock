package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/entity/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

require("stringutility")
require("callable")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace AutoDockButton
AutoDockButton = {}

AutoDockButton.playerIndex = nil

function AutoDockButton.interactionPossible(playerIndex_in, option)
    AutoDockButton.playerIndex = playerIndex_in
    
    ship = Entity()
    if ship:getValue("autoDockShowButton") == true then  --we can only abort in stage 0 of Auto-Docking
        return true
    end
end

function AutoDockButton.getIcon(seed, rarity)
    return "data/textures/icons/contract.png"
end

function AutoDockButton.initUI()
    local res = getResolution()
    local size = vec2(350, 80)

    local menu = ScriptUI()
    window = menu:createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5))
    window.caption = "Abort Auto-Dock?"%_t
    window.showCloseButton = 1
    window.moveable = 1
    menu:registerWindow(window, "Abort Auto-Dock?"%_t);

    local hmsplit = UIHorizontalMultiSplitter(Rect(size), 5, 5, 0.2)

    -- buttons at the bottom
    local buttonYes = window:createButton(hmsplit:partition(0), "Yes"%_t, "onYesButtonPress");
    buttonYes.textSize = 20 
end

function AutoDockButton.onYesButtonPress()
    invokeServerFunction("cancelAutoDock")
end

function AutoDockButton.cancelAutoDock()
    ship = Entity()
    ship:setValue("autoDockAbort", true)
    terminate()
end
callable(AutoDockButton, "cancelAutoDock")