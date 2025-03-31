local screenW, screenH = guiGetScreenSize()


local windowW, windowH = 300, 200
local windowX, windowY = (screenW - windowW) / 2, (screenH - windowH) / 2
local window = guiCreateWindow(windowX, windowY, windowW, windowH, "Vehicle Spawner", false)

local label = guiCreateLabel(20, 40, 260, 30, "Enter Vehicle ID:", false, window)
guiLabelSetHorizontalAlign(label, "center")

local input = guiCreateEdit(50, 70, 200, 30, "", false, window)

local spawnButton = guiCreateButton(50, 120, 200, 40, "Spawn Vehicle", false, window)

guiSetVisible(window, false)


function requestVehicleSpawn()
    local vehicleIDText = guiGetText(input)
    local vehicleID = tonumber(vehicleIDText)

    if not vehicleID then
        outputChatBox("Error: Please enter a valid number!", 255, 0, 0)
        return
    end

    -- Get player position and rotation
    local x, y, z = getElementPosition(localPlayer)
    local rot = getPedRotation(localPlayer)

    -- Calculate spawn position in front of the player
    local offsetDistance = 5
    local spawnX = x + offsetDistance * math.sin(math.rad(-rot))
    local spawnY = y + offsetDistance * math.cos(math.rad(-rot))

    -- Hide GUI
    guiSetVisible(window, false)
    showCursor(false)

    -- Clear input
    guiSetText(input, "")

    outputChatBox("Attempting to spawn vehicle ID: " .. vehicleID .. "...", 255, 255, 0)
    outputDebugString("Sending vehicle ID: " .. vehicleID, 3)

    -- Use root element as the target for server event
    triggerServerEvent("spawnVehicleServer", localPlayer, vehicleID, spawnX, spawnY, z, rot)
end

addEventHandler("onClientGUIClick", spawnButton, requestVehicleSpawn, false)

-- event handler for server responses with improved debugging
addEvent("vehicleSpawnResponse", true)
addEventHandler("vehicleSpawnResponse", localPlayer, function(success, message)
    outputDebugString("Received vehicle spawn response: " .. tostring(success) .. " - " .. tostring(message), 3)
    if success then
        outputChatBox("Success: " .. message, 0, 255, 0)
    else
        outputChatBox("Error: " .. message, 255, 0, 0)
    end
end)

-- enter key handler for the input
function onInputEnter()
    if source == input then
        requestVehicleSpawn()
    end
end

addEventHandler("onClientGUIAccepted", input, onInputEnter)

-- toggle GUI visibility
function toggleGUI()
    local visible = guiGetVisible(window)
    guiSetVisible(window, not visible)
    showCursor(not visible)

    if not visible then -- If showing the window
        guiBringToFront(input)
        guiFocus(input)
    end
end

bindKey("F4", "down", toggleGUI) -- F4 to open/close the GUI
