package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/entity/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

require("stringutility")

playerIndex = nil

function interactionPossible(playerIndex_in, option)
    playerIndex = playerIndex_in
    
    ship = Entity()
    if ship:getValue("autoDockShowButton") == true then  --we can only abort in stage 0 of Auto-Docking
        return true
    end
end

function getIcon(seed, rarity)
    return "data/textures/icons/contract.png"
end

function initUI()
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

function onYesButtonPress()
    invokeServerFunction("cancelAutoDock")
end

function cancelAutoDock()
    ship = Entity()
    ship:setValue("autoDockAbort", true)
    terminate()
end
