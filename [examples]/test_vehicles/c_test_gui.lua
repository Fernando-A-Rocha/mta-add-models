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

    local x, y, z = getElementPosition(localPlayer)
    local rot = getPedRotation(localPlayer)

    local offsetDistance = 5
    local spawnX = x + offsetDistance * math.sin(math.rad(-rot))
    local spawnY = y + offsetDistance * math.cos(math.rad(-rot))

    guiSetVisible(window, false)
    showCursor(false)

    guiSetText(input, "")
    triggerServerEvent("spawnVehicleServer", resourceRoot, localPlayer, vehicleID, spawnX, spawnY, z, rot)
end

addEventHandler("onClientGUIClick", spawnButton, requestVehicleSpawn, false)

addEvent("vehicleSpawnResult", true)
addEventHandler("vehicleSpawnResult", localPlayer, function(success, message)
    if success then
        outputChatBox(message, 0, 255, 0)
    else
        outputChatBox(message, 255, 0, 0)
    end
end)

function onInputEnter()
    if source == input then
        requestVehicleSpawn()
    end
end

addEventHandler("onClientGUIAccepted", input, onInputEnter)

function toggleGUI()
    local visible = guiGetVisible(window)
    guiSetVisible(window, not visible)
    showCursor(not visible)

    if not visible then
        guiBringToFront(input)
        guiFocus(input)
    end
end

bindKey("F4", "down", toggleGUI)
